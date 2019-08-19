package Doodle::Statement;

use 5.014;

use Data::Object 'Class', 'Doodle::Library';

our $VERSION = '0.03'; # VERSION

has cmd => (
  is => 'ro',
  isa => 'Command',
  req => 1
);

has sql => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

1;

=encoding utf8

=head1 NAME

Doodle::Statement

=cut

=head1 ABSTRACT

Doodle Statement Class

=cut

=head1 SYNOPSIS

  use Doodle::Statement;

  my $self = Doodle::Statement->new(%args);

=cut

=head1 DESCRIPTION

Command and DDL statement representation.

=cut
