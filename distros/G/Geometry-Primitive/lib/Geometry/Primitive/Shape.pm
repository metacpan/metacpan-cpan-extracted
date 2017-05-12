package Geometry::Primitive::Shape;
use Moose::Role;

requires 'point_end';
requires 'point_start';
requires 'scale';

no Moose;
1;
__END__
=head1 NAME

Geometry::Primitive::Shape - Shape Role

=head1 DESCRIPTION

Geometry::Primitive::Shape is a geometric shape.

=head1 SYNOPSIS

  with 'Geometry::Primitive::Shape';

  has 'point_end' => '

=head1 METHODS

=head2 grow

Increase the size of this shape by the amount specified.  Consult the shape
implementation's documentation for this works.

=head2 point_end

The end point of this shape.

=head2 point_start

The starting point of this shape.

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 COPYRIGHT & LICENSE

You can redistribute and/or modify this code under the same terms as Perl
itself.