use strict;
use warnings;

package Gentoo::Overlay::Group::INI::Section::Overlays;
BEGIN {
  $Gentoo::Overlay::Group::INI::Section::Overlays::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Overlay::Group::INI::Section::Overlays::VERSION = '0.2.2';
}

# ABSTRACT: Final Target for [Overlays] sections.

use Moose;



sub mvp_multivalue_args {
  return qw( directory );
}

has '_directories' => (
  init_arg => 'directory',
  isa      => 'ArrayRef[ Str ]',
  is       => 'rw',
  traits   => [qw( Array )],
  handles  => { directories => elements =>, },
);


sub overlay_group {
  my ( $self, @rest ) = @_;
  require Gentoo::Overlay::Group;
  my $group = Gentoo::Overlay::Group->new();
  for my $path ( $self->directories ) {
    $group->add_overlay($path);
  }
  return $group;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Gentoo::Overlay::Group::INI::Section::Overlays - Final Target for [Overlays] sections.

=head1 VERSION

version 0.2.2

=head1 SYNOPSIS

  [Overlays]
  directory = a
  directory = b
  directory = c

This is eventually parsed and decoded into one of these objects.

  my @directories = ( $object->directories ); # ( a, b, c )

=head1 METHODS

=head2 mvp_multivalue_args

Tells Config::MVP that C<directory> can be specified multiple times.

=head2 overlay_group

Convert the data stored in this section into a Gentoo::Overlay::Group object.

  $group = $section->overlay_group;

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
