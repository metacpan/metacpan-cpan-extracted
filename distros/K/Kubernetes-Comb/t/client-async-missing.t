use strict;
use warnings;
use Test::More;

# Hide Net::Async::Kubernetes whether it is installed or not.
unshift @INC, sub {
  my ( undef, $file ) = @_;
  die "Can't locate $file in \@INC (hidden by the test)\n"
    if $file eq 'Net/Async/Kubernetes.pm';
  return;
};

my $expected = eval { require IO::Async::Loop; 1 } ? 'Net::Async::Kubernetes' : 'IO::Async::Loop';

ok !eval { require Kubernetes::Comb::Client::Async; 1 },
  'loading the async client without its optional dependency dies';
like $@, qr/\AKubernetes::Comb::Client::Async needs \Q$expected\E, an optional dependency/,
  'naming the missing module';
like $@, qr/Can't locate/, 'with the reason';

ok eval { require Kubernetes::Comb::Client::Sync; 1 }, 'the sync client does not need it'
  or diag $@;

done_testing;
