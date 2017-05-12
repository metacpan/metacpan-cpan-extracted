package Git::TagVersion::Cmd::Command::tag;

use Moose;

extends 'Git::TagVersion::Cmd::Command';

our $VERSION = '1.01'; # VERSION
# ABSTRACT: create a new version tag

has 'push' => (
  is => 'rw', isa => 'Bool', default => 0,
  traits => [ 'Getopt' ],
  cmd_aliases => 'p',
  documentation => 'push new created tag to remote',
);

has 'major' => (
  is => 'ro', isa => 'IncrOption', default => 0,
  traits => [ 'Getopt' ],
  cmd_aliases => [ 'm' ],
  documentation => 'do a (more) major release',
);

has 'minor' => (
  is => 'ro', isa => 'IncrOption', default => 0,
  traits => [ 'Getopt' ],
  documentation => 'add a new minor version level',
);

sub execute {
  my ( $self, $opt, $args ) = @_;

  $self->last_version->push( $self->push );
  if( $self->major ) {
    $self->tag_version->incr_level( $self->major );
  }
  if( $self->minor ) {
    $self->tag_version->add_level( $self->minor );
  }
 
  my $tag = $self->tag_next_version;
  print "tagged $tag\n";

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::TagVersion::Cmd::Command::tag - create a new version tag

=head1 VERSION

version 1.01

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning <ich@markusbenning.de>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
