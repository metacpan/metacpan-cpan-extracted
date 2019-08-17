package Doodle::Command;

use 5.014;

use Data::Object 'Class', 'Doodle::Library';

our $VERSION = '0.01'; # VERSION

has name => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

has doodle => (
  is => 'ro',
  isa => 'Doodle',
  req => 1
);

has schema => (
  is => 'ro',
  isa => 'Maybe[Schema]'
);

has table => (
  is => 'ro',
  isa => 'Table'
);

has columns => (
  is => 'ro',
  isa => 'Columns',
);

has indices => (
  is => 'ro',
  isa => 'Indices',
);

has relation => (
  is => 'ro',
  isa => 'Relation',
);

has data => (
  is => 'ro',
  isa => 'Data'
);

# BUILD

method BUILDARGS(%args) {
  my $data = {};

  my @names = qw(
    name
    doodle
    schema
    table
    columns
    indices
    relation
  );

  for my $name (@names) {
    $data->{$name} = delete $args{$name} if exists $args{$name};
  }

  $data->{columns} = do('array', $data->{columns}) if $data->{columns};
  $data->{indices} = do('array', $data->{indices}) if $data->{indices};

  $data->{data} = do('hash', {%args}) if !$data->{data};

  return $data;
}

1;

=encoding utf8

=head1 NAME

Doodle::Command

=cut

=head1 ABSTRACT

Doodle Command Class

=cut

=head1 SYNOPSIS

  use Doodle::Command;

  my $self = Doodle::Command->new(%args);

=cut

=head1 DESCRIPTION

Description of a DDL statement to build.

=cut
