package Test::Dist;

use Do 'Class';

use Cwd ();
use File::Find ();
use File::Spec::Functions ();
use File::Basename ();

use Test::Dist::File;

has this => (
  is => 'ro',
  isa => 'Str',
  def => $0
);

has here => (
  is => 'ro',
  isa => 'Str',
  def => File::Basename::dirname($0)
);

has home => (
  is => 'ro',
  isa => 'Str',
  def => Cwd::getcwd
);

has libs => (
  is => 'ro',
  isa => 'Str',
  def => join('/', Cwd::getcwd, 'lib')
);

has list => (
  is => 'ro',
  isa => 'ArrayRef',
  def => method(){[]}
);

method BUILD($args) {
  my ($libs, $list) = ($self->libs, $self->list);
  File::Find::find(sub { push @$list, $File::Find::name if -f }, $libs);

  return $args;
}

method paths() {
  my %seen;

  return [grep { $seen{$_}++ ? () : $_ } map {
    (split(/\./, File::Spec::Functions::abs2rel($_, $self->libs), 2))[0]
  } sort @{$self->list}];
}

method render() {
  for my $file (map $self->file("$_"), @{$self->paths}) {
    unlink $file->pod_file; $file->document->output->persist;
  }

  return $self;
}

method file($path) {
  return Test::Dist::File->new(path => $path);
}

1;
