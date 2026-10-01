use strict;
use warnings;
use utf8;
use Test::More;

use lib 't/lib';
use IO::K8s;
use Path::Tiny qw( path tempdir );
use Kubernetes::Comb;
use Kubernetes::Comb::Static;
use Kubernetes::Comb::Role::Static;
use Kubernetes::Comb::Client::Fake;
use TestComb::Fixtures qw( comb_cr comb_labels );
use TestComb::Mailer;

my $DATA = path('t/data/static')->absolute;

# The files and the directory a test wants, handed out by the classes below.
our @FILES;
our $DIR = $DATA;

{
  package TestComb::Parts;
  use Moo;
  extends 'Kubernetes::Comb::Static';
  sub name           { 'parts' }
  sub manifest_dir   { $main::DIR }
  sub manifest_files { @main::FILES }
}

{
  package TestComb::Plain;
  use Moo;
  extends 'Kubernetes::Comb';
  with 'Kubernetes::Comb::Role::Static';
  sub name           { 'plain' }
  sub manifest_files { @main::FILES }
}

{
  # A stub that keeps the contract of TestComb::Mailer by inheriting it and
  # takes its manifests from a file instead.
  package TestComb::Mailer::FileStub;
  use Moo;
  extends 'TestComb::Mailer';
  with 'Kubernetes::Comb::Role::Static';
  sub manifest_dir   { 't/data/static' }
  sub manifest_files { 'mailpit.pk8s' }
}

sub parts {
  my ( %args ) = @_;
  my $k8s = Kubernetes::Comb::Client::Fake->new;
  return ( TestComb::Parts->new( k8s => $k8s, namespace => 'platform', %args ), $k8s );
}

sub kinds_names { map { $_->kind.'/'.$_->metadata->name } @_ }

subtest '.pk8s and multi-document YAML, in the order of the files' => sub {
  local @FILES = ( 'mailpit.pk8s', 'parts.yaml' );
  my ( $comb ) = parts();
  my @manifests = $comb->manifests;
  is_deeply [ kinds_names(@manifests) ], [
    'Deployment/mailer', 'Service/mailer', 'Service/mailer-web',
    'ConfigMap/parts-config', 'Service/parts'
  ], 'every object of every file, empty YAML documents skipped';
  isa_ok $manifests[0], 'IO::K8s::Api::Apps::V1::Deployment';
  isa_ok $manifests[3], 'IO::K8s::Api::Core::V1::ConfigMap';
  is $manifests[3]->data->{mode}, 'static', 'content loaded';
  is $manifests[0]->metadata->namespace, undef, 'no namespace until deploy';
};

subtest 'deploy labels them and puts the namespace on them' => sub {
  local @FILES = ( 'mailpit.pk8s', 'parts.yaml' );
  my ( $comb, $k8s ) = parts();
  my @stored = $comb->deploy->get;
  is scalar @stored, 5, 'five objects stored';
  my @sent = map { $_->[0] } $k8s->calls_of('ensure');
  is_deeply [ kinds_names(@sent) ], [ kinds_names( $comb->manifests ) ], 'applied in file order';
  my %labels = comb_labels('parts');
  is_deeply [ map { $_->metadata->labels } @sent ], [ ( {%labels} ) x 5 ],
    'the Comb labels on every object';
  is_deeply [ map { $_->metadata->namespace } @sent ], [ ('platform') x 5 ], 'namespace defaulted';
  is_deeply $sent[0]->spec->template->metadata->labels, { app => 'mailer', %labels },
    'the pod template of the workload labelled';
  ok !( grep { $_->metadata->labels && $_->metadata->labels->{'comb.internal/comb'} } $comb->manifests ),
    'the loaded objects themselves are not changed';
};

subtest 'paths' => sub {
  my $tmp = tempdir;
  local $DIR   = $tmp;
  local @FILES = ( $DATA->child('greeting.yml')->stringify );
  is_deeply [ kinds_names( ( parts() )[0]->manifests ) ], ['ConfigMap/greeting'],
    'an absolute path ignores manifest_dir';

  local @FILES = ('greeting.yml');
  local $DIR   = 't/data/static';
  is_deeply [ kinds_names( ( parts() )[0]->manifests ) ], ['ConfigMap/greeting'],
    'a relative manifest_dir is taken from the current directory';

  local @FILES = ('t/data/static/greeting.yml');
  my $plain = TestComb::Plain->new( k8s => Kubernetes::Comb::Client::Fake->new, namespace => 'platform' );
  is_deeply [ kinds_names( $plain->manifests ) ], ['ConfigMap/greeting'],
    'without manifest_dir relative to the current directory';
};

subtest 'non-ASCII text' => sub {
  local @FILES = ( 'greeting.yml', 'greeting.pk8s' );
  my ( $comb ) = parts();
  my ( $yaml, $pk8s ) = $comb->manifests;
  is $yaml->data->{text}, 'Grüße aus Köln', 'YAML is read as UTF-8';
  is $pk8s->data->{text}, 'Grüße aus Köln', 'a .pk8s with use utf8 as well';
};

subtest 'read once per instance' => sub {
  my $tmp = tempdir;
  $DATA->child('parts.yaml')->copy( $tmp->child('parts.yaml') );
  local $DIR   = $tmp;
  local @FILES = ('parts.yaml');
  my ( $comb ) = parts();
  is scalar( my @first = $comb->manifests ), 2, 'loaded';

  $tmp->child('parts.yaml')->remove;
  my @again = eval { $comb->manifests };
  is_deeply [ kinds_names(@again) ], [ kinds_names(@first) ],
    'the same instance does not read the files again';
  is $comb->status->get->{phase}, 'NotDeployed', 'status renders from what it read';

  my ( $fresh ) = parts();
  my $f = $fresh->deploy;
  ok $f->is_failed, 'a new instance reads them again';
};

subtest 'a failed read is not kept' => sub {
  my $tmp = tempdir;
  local $DIR   = $tmp;
  local @FILES = ('parts.yaml');
  my ( $comb ) = parts();
  ok !eval { $comb->manifests; 1 }, 'missing file dies';
  $DATA->child('parts.yaml')->copy( $tmp->child('parts.yaml') );
  is scalar( my @m = $comb->manifests ), 2, 'the next call reads it';
};

subtest 'errors name the file, and are failed Futures in the lifecycle' => sub {
  my %cases = (
    'missing.yaml' => qr{TestComb::Parts: manifest file \S+/t/data/static/missing\.yaml does not exist},
    'notes.txt'    => qr{TestComb::Parts: manifest file \S+/notes\.txt is neither \.pk8s nor \.yaml/\.yml},
    'broken.yaml'  => qr{TestComb::Parts: cannot load manifest file \S+/broken\.yaml: },
    'broken.pk8s'  => qr{TestComb::Parts: cannot load manifest file \S+/broken\.pk8s: .*broken on purpose}s,
    'widget.yaml'  => qr{TestComb::Parts: cannot load manifest file \S+/widget\.yaml: .*Widget}s
  );
  for my $file ( sort keys %cases ) {
    local @FILES = ( 'parts.yaml', $file );
    my ( $comb, $k8s ) = parts();
    ok !eval { $comb->manifests; 1 }, $file.': manifests dies';
    like $@, $cases{$file}, $file.': message';
    my $f = $comb->deploy;
    ok $f->is_failed, $file.': deploy is a failed Future';
    like scalar $f->failure, $cases{$file}, $file.': with the message';
    is scalar $k8s->calls_of('ensure'), 0, $file.': nothing applied';
  }
};

subtest 'the Comb\'s io_k8s parses the files' => sub {
  local @FILES = ('widget.yaml');
  my ( $comb ) = parts( io_k8s => IO::K8s->new( unknown_kinds => 'unstructured' ) );
  my ( $widget ) = $comb->manifests;
  isa_ok $widget, 'IO::K8s::Unstructured', 'a Kind only that IO::K8s accepts';
  is $widget->TO_JSON->{spec}{size}, 3, 'content kept';
};

subtest 'a stub from a .pk8s file' => sub {
  my $cr = comb_cr( name => 'mailer', class => 'TestComb::Mailer' );
  my $mailer = TestComb::Mailer->new( k8s => Kubernetes::Comb::Client::Fake->new, crd => $cr );
  my $stub = TestComb::Mailer::FileStub->new(
    k8s     => Kubernetes::Comb::Client::Fake->new,
    crd     => $cr,
    stub_of => $mailer
  );
  ok $stub->is_stub, 'built as the stub of the Mailer, contract kept';
  is_deeply [ kinds_names( $stub->manifests ) ],
    [ 'Deployment/mailer', 'Service/mailer', 'Service/mailer-web' ],
    'the file replaces the inherited manifests';
  my ( $deployment ) = $stub->manifests;
  is $deployment->spec->template->spec->containers->[0]->image, 'axllent/mailpit', 'the Mailpit';

  my $by_class = Kubernetes::Comb->from_crd(
    comb_cr( name => 'mailer', class => 'TestComb::Mailer::FileStub' ),
    k8s => Kubernetes::Comb::Client::Fake->new
  );
  isa_ok $by_class, 'TestComb::Mailer::FileStub', 'spec.class naming the stub';
  my @endpoints = map { $_->name } $by_class->_resolve_endpoints->get;
  is_deeply \@endpoints, [ 'smtp', 'http' ], 'with the endpoints of the Mailer';
};

subtest 'the contract of the role' => sub {
  ok !eval q{
    package TestComb::NoFiles;
    use Moo;
    extends 'Kubernetes::Comb';
    with 'Kubernetes::Comb::Role::Static';
    1;
  }, 'composing it without manifest_files dies';
  like $@, qr/manifest_files/, 'naming the missing method';

  my $bare = Kubernetes::Comb::Static->new( k8s => Kubernetes::Comb::Client::Fake->new, namespace => 'platform' );
  ok !eval { $bare->manifests; 1 }, 'Kubernetes::Comb::Static without files dies';
  like $@, qr/Kubernetes::Comb::Static has no manifest files: override manifest_files/, 'saying what to do';

  ok !TestComb::Plain->can($_), 'no '.$_.' imported into the consumer' for qw( croak path );
};

done_testing;
