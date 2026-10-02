#!/usr/bin/env perl
# ABSTRACT: Langfuse batches stay bounded when nobody flushes

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::Engine::OpenAI;
use Langertha::Plugin::Langfuse;

# Langfuse turns itself on from LANGFUSE_PUBLIC_KEY / LANGFUSE_SECRET_KEY, and
# the engine then records every simple_chat call. Nothing is sent until someone
# flushes, so a long-running process that only has the variables set kept every
# prompt and answer in memory forever (karr k305). The batch is now capped:
# oldest events go first, with exactly one warning per object.

sub capture_warnings {
  my ($code) = @_;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  $code->();
  return @warnings;
}

subtest 'engine: env-enabled Langfuse keeps at most langfuse_max_batch events' => sub {
  local $ENV{LANGFUSE_PUBLIC_KEY} = 'pk-lf-env';
  local $ENV{LANGFUSE_SECRET_KEY} = 'sk-lf-env';
  my $engine = Langertha::Engine::OpenAI->new(
    api_key            => 'testkey',
    model              => 'gpt-4o-mini',
    langfuse_max_batch => 5,
  );
  ok( $engine->langfuse_enabled, 'enabled from the environment alone' );

  my @warnings = capture_warnings(sub {
    $engine->langfuse_trace( name => "trace-$_" ) for 1 .. 12;
  });

  is( scalar @{ $engine->_langfuse_batch }, 5, 'batch capped at langfuse_max_batch' );
  is_deeply(
    [ map { $_->{body}{name} } @{ $engine->_langfuse_batch } ],
    [ map { "trace-$_" } 8 .. 12 ],
    'the oldest events were dropped, the newest kept',
  );
  is( scalar @warnings, 1, 'exactly one warning for the whole overflow' );
  like( $warnings[0], qr/langfuse_max_batch \(5 events\).*langfuse_flush/s,
    'warning names the cap and the remedy' );
};

subtest 'engine: default cap is 1000, 0 disables it' => sub {
  my $default = Langertha::Engine::OpenAI->new(
    api_key => 'testkey', langfuse_public_key => 'pk', langfuse_secret_key => 'sk',
  );
  is( $default->langfuse_max_batch, 1000, 'default cap' );

  my $uncapped = Langertha::Engine::OpenAI->new(
    api_key => 'testkey', langfuse_public_key => 'pk', langfuse_secret_key => 'sk',
    langfuse_max_batch => 0,
  );
  my @warnings = capture_warnings(sub {
    $uncapped->langfuse_trace( name => "t$_" ) for 1 .. 1500;
  });
  is( scalar @{ $uncapped->_langfuse_batch }, 1500, 'langfuse_max_batch => 0 keeps everything' );
  is( scalar @warnings, 0, 'and does not warn' );
};

subtest 'plugin: max_batch caps the batch the same way' => sub {
  my $lf = Langertha::Plugin::Langfuse->new(
    host       => bless( {}, 'NoHost' ),
    public_key => 'pk',
    secret_key => 'sk',
    max_batch  => 3,
  );
  my @warnings = capture_warnings(sub {
    $lf->create_trace( name => "t$_" ) for 1 .. 7;
  });
  is_deeply( [ map { $_->{body}{name} } @{ $lf->_batch } ], [qw( t5 t6 t7 )],
    'oldest dropped, newest three kept' );
  is( scalar @warnings, 1, 'one warning' );
  like( $warnings[0], qr/max_batch \(3 events\)/, 'warning names the cap' );
};

done_testing;
