package Test::Dist::File;

use Do 'Class';

use File::Spec::Functions ();

use Carp;
use Data::Object::Data;
use Test::Dist::Document;

has path => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

has data => (
  is => 'rw',
  isa => 'HashRef',
  def => sub{{}}
);

method name() {
  my $path = $self->path;

  return $path =~ s/[\/\\]+/_/gr;
}

method package() {
  my $path = $self->path;

  return $path =~ s/[\/\\]+/::/gr;
}

method parse($file) {
  return Data::Object::Data->new(file => $file);
}

method document() {
  return Test::Dist::Document->new(file => $self);
}

method lib_file() {
  my $path = $self->path;
  my $file = File::Spec::Functions::catfile(
    "lib", "${path}.pm"
  );

  return $file;
}

method pod_file() {
  my $path = $self->path;
  my $file = File::Spec::Functions::catfile(
    "lib", "${path}.pod"
  );

  return $file;
}

method use_file() {
  my $name = $self->name;
  my $file = File::Spec::Functions::catfile(
    "t", "0.90", "use", "${name}.t"
  );

  return $file;
}

method can_file($test) {
  my $name = $self->name;
  my $file = File::Spec::Functions::catfile("t", "0.90", "can", "${name}_${test}.t");

  return $file;
}

method can_files() {
  my $routines = $self->routines;

  return [map $self->can_file("$_"), @$routines];
}

method routines() {
  my $re = 'fun|method|sub';

  my %ignore = map +($_, 1), qw(
    BUILD
    BUILD_ARGS
    BUILD_DATA
    BUILD_OPTS
    BUILD_VARS
    BUILDARGS
    BUILDPROXY
    import
  );

  my %seen;

  my $lines = $self->source($self->lib_file);

  my @finds = map { /^(?:$re)\s+([a-zA-Z]\w+).*\{$/ } @$lines;

  if ($self->data->{routines}) {
    my %seen = map +($_, 1), @finds;

    push @finds, grep !$seen{$_}++, @{$self->data->{routines}};
  }

  return [sort grep !$ignore{$_}, sort @finds];
}

method source($file) {
  open my $fh, '<', "$file" or confess "Can't open $file: $!";

  return [map { chomp; $_ } <$fh>];
}

1;
