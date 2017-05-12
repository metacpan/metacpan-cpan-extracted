package Git::TagVersion::App;

use Moose;
use Moose::Util::TypeConstraints;

our $VERSION = '1.01'; # VERSION
# ABSTRACT: commandline wrapper for Git::TagVersion

extends 'Git::TagVersion';
with 'MooseX::Getopt';

has '+root' => ( traits => [ 'NoGetopt' ] );
has '+repo' => ( traits => [ 'NoGetopt' ] );
has '+last_version' => ( traits => [ 'NoGetopt' ] );
has '+version_regex' => ( traits => [ 'NoGetopt' ] );
has '+versions' => ( traits => [ 'NoGetopt' ] );
has '+next_version' => ( traits => [ 'NoGetopt' ] );

has '+fetch' => (
  traits => [ 'Getopt' ],
  cmd_aliases => 'f',
  documentation => 'fetch remote refs before finding last version',
);

has '+push' => (
  traits => [ 'Getopt' ],
  cmd_aliases => 'p',
  documentation => 'push new created tag to remote',
);

has 'all' => (
  is => 'ro', isa => 'Bool', default => 0,
  traits => [ 'Getopt' ],
  cmd_aliases => [ 'a', 'list-all' ],
  documentation => 'list all existing versions',
);

has 'last' => (
  is => 'ro', isa => 'Bool', default => 0,
  traits => [ 'Getopt' ],
  cmd_aliases => [ 'l', 'last-version' ],
  documentation => 'display last version',
);

subtype 'IncrOption' => as 'Int';

MooseX::Getopt::OptionTypeMap->add_option_type_to_map(
  'IncrOption' => '+'
);

has '+incr_level' => (
  is => 'ro', isa => 'IncrOption', default => 0,
  traits => [ 'Getopt' ],
  cmd_aliases => [ 'major', 'm' ],
  documentation => 'do a (more) major release',
);

has '+add_level' => (
  is => 'ro', isa => 'IncrOption', default => 0,
  traits => [ 'Getopt' ],
  cmd_aliases => [ 'minor' ],
  documentation => 'add a new minor version level',
);

has 'next' => (
  is => 'ro', isa => 'Bool', default => 0,
  traits => [ 'Getopt' ],
  cmd_aliases => [ 'n', 'next-version' ],
  documentation => 'display next version',
);

has 'tag' => (
  is => 'ro', isa => 'Bool', default => 0,
  traits => [ 'Getopt' ],
  cmd_aliases => [ 't', 'tag-next-version' ],
  documentation => 'create tag for next version',
);

sub run {
  my $self = shift;

  if( $self->all ) {
    $self->print_versions;
  } elsif( $self->last ) {
    $self->print_last_version
  } elsif( $self->next ) {
    $self->print_next_version
  } elsif( $self->tag ) {
    $self->print_tag_next_version
  }

  return;
}

sub print_tag_next_version {
  my $self = shift;

  my $tag = $self->tag_next_version;
  print "tagged $tag\n";

  return;
}

sub print_next_version {
  my $self = shift;

  if( defined $self->next_version ) {
    print $self->next_version->as_string."\n";
  }

  return;
}

sub print_last_version {
  my $self = shift;

  if( defined $self->last_version ) {
    print $self->last_version->as_string."\n";
  }

  return;
}

sub print_versions {
  my $self = shift;

  foreach my $v ( @{$self->versions} ) {
    print $v->as_string."\n";
  }

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::TagVersion::App - commandline wrapper for Git::TagVersion

=head1 VERSION

version 1.01

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning <ich@markusbenning.de>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
