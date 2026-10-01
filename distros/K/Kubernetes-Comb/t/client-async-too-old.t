use strict;
use warnings;
use Test::More;

# A Net::Async::Kubernetes that is installed but too old is refused when the
# async client is loaded, like a missing one. What is installed on this
# machine does not matter: both optional dependencies are stand-ins on a
# temporary include path in front of everything else, one child perl per
# version.

use IPC::Open3 qw( open3 );
use Path::Tiny qw( tempdir );

my $needed = '0.009';

# Loads the async client in a child perl that finds a Net::Async::Kubernetes
# of that version (none at all with undef). Output is stdout and stderr
# together.
sub load_with {
  my ( $version ) = @_;
  my $dir = tempdir;
  $dir->child('IO/Async')->mkpath;
  $dir->child('IO/Async/Loop.pm')->spew_utf8(
    'package IO::Async::Loop;'."\n".'our $VERSION = \'0.800\';'."\n".'1;'."\n"
  );
  $dir->child('Net/Async')->mkpath;
  $dir->child('Net/Async/Kubernetes.pm')->spew_utf8(
    'package Net::Async::Kubernetes;'."\n"
    .( defined $version ? 'our $VERSION = \''.$version.'\';'."\n" : '' )
    .'1;'."\n"
  );
  my $pid = open3(
    my $in, my $out, undef,
    $^X, ( map { '-I'.$_ } $dir, grep { !ref } @INC ),
    '-e', 'require Kubernetes::Comb::Client::Async; print qq{loaded\n}'
  );
  close $in;
  my $output = do { local $/; <$out> };
  waitpid $pid, 0;
  return ( $? == 0, $output, $dir );
}

subtest 'older than needed' => sub {
  my ( $ok, $output, $dir ) = load_with('0.008');
  ok !$ok, 'loading the async client with Net::Async::Kubernetes 0.008 dies';
  like $output,
    qr/\AKubernetes::Comb::Client::Async needs Net::Async::Kubernetes \Q$needed\E or newer, an optional dependency of Kubernetes::Comb/,
    'naming the module and the version needed';
  like $output, qr/found 0\.008 /, 'and the version found';
  like $output, qr/\Q$dir\E/, 'and where it was found';
  unlike $output, qr/^loaded$/m, 'nothing ran after the load';
};

subtest 'without a version' => sub {
  my ( $ok, $output ) = load_with(undef);
  ok !$ok, 'a Net::Async::Kubernetes without a $VERSION is refused too';
  like $output,
    qr/\AKubernetes::Comb::Client::Async needs Net::Async::Kubernetes \Q$needed\E or newer/,
    'naming the module and the version needed';
  like $output, qr/found one without a version /, 'and that it has none';
};

subtest 'new enough' => sub {
  for my $version ( $needed, '0.010', '1.000' ) {
    my ( $ok, $output ) = load_with($version);
    ok $ok, 'loads with Net::Async::Kubernetes '.$version or diag $output;
    like $output, qr/^loaded$/m, '... all the way';
  }
};

done_testing;
