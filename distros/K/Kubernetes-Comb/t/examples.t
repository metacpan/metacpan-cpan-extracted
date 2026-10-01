use strict;
use warnings;
use Test::More;

# The examples are documentation: they have to compile, and what they drive
# -- the example Comb classes, the stub file, combs.yaml -- has to load. No
# cluster: nothing here builds a client or sends a request.

use lib 'examples/lib', 't/lib';
use IO::K8s;
use IPC::Open3 qw( open3 );
use Module::Runtime qw( require_module );
use Path::Tiny qw( path );
use Kubernetes::Comb;
use Kubernetes::Comb::CRD;
use TestComb::AsyncClient qw( async_client_refusal );

# perl -c in a child: the scripts run their BEGIN blocks and use lines, not
# their code. Output is stdout and stderr together.
sub compiles {
  my ( $script ) = @_;
  my $pid = open3( my $in, my $out, undef, $^X, '-c', '-Ilib', '-Iexamples/lib', $script );
  close $in;
  my $output = do { local $/; <$out> };
  waitpid $pid, 0;
  return ( $? == 0, $output );
}

{
  my ( $ok, $output ) = compiles('examples/sync.pl');
  ok $ok, 'examples/sync.pl compiles' or diag $output;
}

SKIP: {
  my $refusal = async_client_refusal;
  skip 'examples/async.pl: '.$refusal, 1 if defined $refusal;
  skip 'examples/async.pl needs Future::AsyncAwait', 1
    unless eval { require_module('Future::AsyncAwait'); 1 };
  my ( $ok, $output ) = compiles('examples/async.pl');
  ok $ok, 'examples/async.pl compiles' or diag $output;
}

require_ok($_) for qw(
  Example::Comb::NATS
  Example::Comb::DB
  Example::Comb::Mailer
  Example::Comb::Mailer::Stub
);

my $crs = IO::K8s->new( with => [ Kubernetes::Comb::CRD->new ] )
  ->load_yaml( path('examples/combs.yaml')->slurp_utf8 );
is_deeply [ map { $_->metadata->name.' '.$_->spec->class } @$crs ], [
  'nats Example::Comb::NATS',
  'db Example::Comb::DB',
  'mailer Example::Comb::Mailer'
], 'combs.yaml holds the three Combs';

for my $cr (@$crs) {
  $cr->metadata->namespace('comb-demo');
  my $comb = Kubernetes::Comb->from_crd($cr);
  isa_ok $comb, $cr->spec->class, 'the Comb of '.$cr->metadata->name;
  my @manifests = $comb->manifests;
  ok @manifests, $cr->metadata->name.' renders manifests';
}

my ( $mailer ) = grep { $_->metadata->name eq 'mailer' } @$crs;
my $stub = Kubernetes::Comb->from_crd( $mailer, stub => sub { 1 } );
isa_ok $stub, 'Example::Comb::Mailer::Stub', 'the stub of mailer';
is ref $stub->stub_of, 'Example::Comb::Mailer', 'standing in for the Mailer';
is_deeply [ map { $_->kind.' '.$_->metadata->name } $stub->manifests ],
  [ 'Deployment mailer', 'Service mailer' ], 'its manifests come from Stub.pk8s';
is_deeply [ $stub->check ], [], 'it needs no relay';

done_testing;
