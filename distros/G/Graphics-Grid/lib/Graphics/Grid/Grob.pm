package Graphics::Grid::Grob;

# ABSTRACT: Role for graphical object (grob) classes in Graphics::Grid

use Graphics::Grid::Role;

our $VERSION = '0.0001'; # VERSION

use Types::Standard qw(InstanceOf Str);
use namespace::autoclean;

use Graphics::Grid::GPar;
use Graphics::Grid::Types qw(:all);


has vp => ( is => 'ro', isa => InstanceOf ["Graphics::Grid::Viewport"] );


has elems => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_elems',
    init_arg => undef
);

has name => ( is => 'ro', isa => Str, default => '' );

with qw(
  Graphics::Grid::HasGPar
);


# TODO: Make this a lazy attr, to avoid validating a grob for multiple times.
sub validate { }

requires '_build_elems';    # for attr "elems"

requires 'draw';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Grob - Role for graphical object (grob) classes in Graphics::Grid

=head1 VERSION

version 0.0001

=head1 DESCRIPTION

This is the role for graphical object (grob) classes.

=head1 ATTRIBUTES

=head2 vp

A viewport object. When drawing a grob, if the grob has this attribute, the
viewport would be temporily pushed onto the global viewport stack before drawing
takes place, and be poped after drawing. If the grob does not have this attribute
set, it would be drawn on the existing current viewport in the global viewport
stack. 

=head2 elems

Get number of sub-elements in the grob.

Grob classes shall implement a C<_build_elems()> method to support this
attribute.

=head1 SEE ALSO

L<Graphics::Grid>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
