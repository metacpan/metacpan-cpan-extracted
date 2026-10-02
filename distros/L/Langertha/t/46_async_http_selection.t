#!/usr/bin/env perl
# ABSTRACT: Role::AsyncHTTP picks injected > Net::Async::HTTP > sync shim (warn once)
use strict; use warnings;
use Test2::Bundle::More;

{
  package FakeEngine;
  use Moose;
  has user_agent => (is => 'ro', default => sub { bless {}, 'FakeUA' });
  with 'Langertha::Role::AsyncHTTP';
  __PACKAGE__->meta->make_immutable;
}

# injected client wins
{
  my $injected = bless {}, 'MyClient';
  my $engine = FakeEngine->new( _async_http => $injected );
  is($engine->_async_http, $injected, 'injected _async_http is used verbatim');
}

# Net::Async::HTTP installed -> the real async client, no warning. Runs before
# the blocked case below, whose warning is once per process.
SKIP: {
  skip 'Net::Async::HTTP not installed', 3
    unless eval { require Net::Async::HTTP; require IO::Async::Loop; 1 };
  my @warnings; local $SIG{__WARN__} = sub { push @warnings, "@_" };
  my $engine = FakeEngine->new;
  isa_ok($engine->_async_http, ['Net::Async::HTTP'], 'Net::Async::HTTP selected when available');
  is($engine->_async_http->loop, $engine->_async_loop, 'client added to the engine loop');
  is(scalar @warnings, 0, 'no fallback warning when the async client is available');
}

# no Net::Async::HTTP -> sync shim + exactly one warning. The hook fails the
# way a real missing module does, so this is the "not available" wording.
{
  local @INC = (sub {
    my (undef, $file) = @_;
    die "Can't locate $file in \@INC (blocked by test)\n" if $file eq 'Net/Async/HTTP.pm';
    return;
  }, @INC);
  local $INC{'Net/Async/HTTP.pm'};
  delete $INC{'Net/Async/HTTP.pm'};
  my @warnings; local $SIG{__WARN__} = sub { push @warnings, "@_" };
  my $engine = FakeEngine->new;
  isa_ok($engine->_async_http, ['Langertha::Request::SyncHTTP'], 'falls back to sync shim'); my $line = __LINE__;
  my $engine2 = FakeEngine->new;
  $engine2->_async_http;
  is(scalar(grep { /synchronous/i } @warnings), 1, 'warns exactly once per process');
  like($warnings[0], qr/\ANet::Async::HTTP not available; Langertha is running HTTP synchronously/,
    'missing module: the documented "not available" wording');
  like($warnings[0], qr/ at \Q${\ __FILE__ }\E line \Q$line\E\.$/,
    'warning points at the caller, not at Moose accessor internals');
}

# Installed but broken (e.g. an IO::Async sub-dependency missing after a
# partial upgrade): say so and show the load error. Fresh process, because the
# warning is once per process.
{
  my $script = <<'PERL';
BEGIN { unshift @INC, sub { die "Can't locate IO/Async/Stream.pm in \@INC (simulated broken install)\n" if $_[1] eq 'IO/Async/Stream.pm'; return } }
BEGIN { unshift @INC, sub { return unless $_[1] eq 'Net/Async/HTTP.pm'; my $src = "package Net::Async::HTTP; require IO::Async::Stream; 1;\n"; open my $fh, '<', \$src; return $fh } }
package FakeEngine;
use Moose;
has user_agent => (is => 'ro', default => sub { bless {}, 'FakeUA' });
with 'Langertha::Role::AsyncHTTP';
package main;
print ref(FakeEngine->new->_async_http), "\n";
PERL
  require File::Temp;
  my ($fh, $path) = File::Temp::tempfile(SUFFIX => '.pl', UNLINK => 1);
  print {$fh} $script; close $fh;
  require File::Spec;
  my $lib = File::Spec->rel2abs('lib');
  my $output = `"$^X" -I"$lib" "$path" 2>&1`;
  like($output, qr/Langertha::Request::SyncHTTP/, 'broken install still falls back to the sync shim');
  like($output, qr/Net::Async::HTTP failed to load \(Can't locate IO\/Async\/Stream\.pm in \@INC \(simulated broken install\)\); Langertha is running HTTP synchronously/,
    'broken install: warning names the load error instead of "not available"');
}

done_testing;
