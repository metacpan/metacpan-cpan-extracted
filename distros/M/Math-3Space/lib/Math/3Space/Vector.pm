package Math::3Space::Vector;

our $VERSION = '0.006'; # VERSION
# ABSTRACT: Object wrapping a buffer of three doubles

use Exporter 'import';
our @EXPORT_OK= qw( vec3 );

# All methods handled by XS
require Math::3Space;

use overload '""' => sub { "[@{[$_[0]->xyz]}]" };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::3Space::Vector - Object wrapping a buffer of three doubles

=head1 SYNOPSIS

  use Math::3Space::Vector 'vec3';
  
  $vec= vec3(1,2,3);
  
  say $vec->x;
  $vec->x(12);
  
  ($x, $y, $z)= $vec->xyz;
  $vec->set(4,3,2);
  
  $dot_product= vec3(0,1,0)->dot(1,0,0);
  $cross_product= vec3(1,0,0)->cross(0,0,1);

=head1 DESCRIPTION

This object is a blessed scalar-ref of a buffer of floating point numbers (Perl's float type,
either double or long double).  The vector is always 3 elements long.  For more general vector
classes, see many other modules on CPAN.  This is simply an efficient way for the 3Space object
to pass vectors around without fully allocating Perl structures for them.

=head1 CONSTRUCTOR

=head2 vec3

  $vec= vec3($x, $y, $z);
  $vec= vec3([ $x, $y, $z ]);
  $vec= vec3({ x => $x, y => $y, z => $z });
  $vec= pdl([ $x, $y, $z ]);
  $vec2= vec3($vec);

=head2 new

  $vec= Math::3Space::Vector->new(); # 0,0,0
  $vec= Math::3Space::Vector->new([ $x, $y, $z ]);
  $vec= Math::3Space::Vector->new(x => $x, y => $y, z => $z);
  $vec= Math::3Space::Vector->new({ x => $x, y => $y, z => $z });
  $vec= Math::3Space::Vector->new(pdl([ $x, $y, $z ]));

=head1 ATTRIBUTES

=head2 x

Read/write 'x' field.

=head2 y

Read/write 'y' field.

=head2 z

Read/write 'z' field.

=head2 xyz

Read list of (x,y,z).

=head2 magnitude

  $mag= $vector->magnitude;
  $vector->magnitude($new_length);

Read/write length of vector.  Attempting to write to a vector with length 0 emits a warning and
does nothing.

=head1 METHODS

=head2 set

  $vector->set($vec2);
  $vector->set($x,$y,$z);
  $vector->set([$x,$y,$z]);

=head2 add

  $vector->add($vec2);
  $vector->add($x,$y);
  $vector->add($x,$y,$z);
  $vector->add([$x,$y,$z]);

=head2 sub

  $vector->sub($vec2);
  $vector->sub($x,$y);
  $vector->sub($x,$y,$z);
  $vector->sub([$x,$y,$z]);

=head2 scale

  $vector->scale($scale); # x= y= z= $scale
  $vector->scale($x, $y); # z= 1
  $vector->scale($x, $y, $z);
  $vector->scale([$x, $y, $z]);
  $vector->scale($vec2);

Multiply each component of the vector by a scalar.

=head2 dot

  $prod= $vector->dot($vector2);
  $prod= $vector->dot($x,$y,$z);
  $prod= $vector->dot([$x,$y,$z]);

Dot product with another vector.

=head2 cos

  $cos= $vector->cos($vector2);
  $cos= $vector->cos($x,$y,$z);
  $cos= $vector->cos([$x,$y,$z]);

Return the vector-cosine to the other vector.  This is the same as the dot product divided by
the magnitudes of the vectors, or identical to the dot product when the vectors are unit-length.
This dies if either vector is zero length (or too close to zero for available floating precision).

=head2 cross

  $c= $a->cross($b);
  $c= $a->cross($bx, $by, $bz);
  $c= $a->cross([$bx, $by, $bz]);
  $c->cross($a, $b);

Return a new vector which is the cross product C<< A x B >>, or if called with 2 parameters
assign the cross product to the object itself.

=head1 SEE ALSO

=over

=item L<PDL>

Perl Data Language ndarray are a good alternative, allowing for operations on many vectors in parallel.

=back

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.006

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
