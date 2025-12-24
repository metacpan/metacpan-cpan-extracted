use 5.008008;
use strict;
use warnings;
use utf8;

package Marlin::Struct;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.008000';

use Marlin ();

my $uniq_id = 0;

sub import {
	my $me = shift;
	my $caller = caller;
	
	my %defs;
	
	while ( @_ ) {
		my ( $name, $definition ) = splice @_, 0, 2;
		my $class_name = sprintf '%s::__ANON__::_%06d', $me, ++$uniq_id;
		
		my $marlin = Marlin->new(
			'-caller' => [ $caller ],
			'-this'   => [ $class_name ],
			@$definition,
		);
		$defs{$name} = $marlin;
		@{ $marlin->parents } = map {
			$defs{$_->[0]} ? [ $defs{$_->[0]}->this ] : $_
		} @{ $marlin->parents };
		$marlin->{short_name} = $name;
		$marlin->{is_struct}  = !!1;
		$marlin->store_meta;
		$marlin->do_setup;
		
		Type::Tiny::_install_overloads(
			$marlin->this,
			q(@{})   => sub { $marlin->to_arrayref( @_ ) },
			q("")    => sub { $marlin->to_string( @_ ) },
			q(bool)  => sub { !!1 },
		);
		
		my $type = $marlin->make_type_constraint( $name );
		my @exportables = @{ $type->exportables };
		for my $e ( @exportables ) {
			Eval::TypeTiny::set_subname( $me . '::' . $e->{name}, $e->{code} );
			$marlin->_lexport( $e->{name}, $e->{code} );
		}
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Marlin::Struct - quickly create struct-like classes

=head1 SYNOPSIS

  use v5.20.0;
  use Types::Common 'Num';
  
  use Marlin::Struct
    Point    => [ 'x!' => Num, 'y!' => Num ],
    Point3D  => [ 'z!' => Num, -parent => \'Point' ];
  
  my $point   = Point->new( x => 1, y => 2 );
  my $point3d = Point3D[ 1, 2, 3 ];
  
  is_Point( $point3d ) or die;
  assert_Point( $point3d );
  
  use Marlin::Struct
    Rectangle => [ 'corner1!' => Point, 'corner2! => Point ]; 

=head1 DESCRIPTION

This module quickly creates "anonymous-like" classes and gives you a lexical
function to construct instances.

The C<< use Marlin::Struct >> line accepts a list of key-value pairs. Each
key should be the name you want to use for the class. This is B<not> a Perl
package name, but an UpperCamelCase string which will only be available
lexically. The value should be a L<Marlin> definition of the class.

Taking C<Point> from the L</SYNOPSIS> as an example, Marlin::Struct will
export (lexically if your Perl version is 5.12+) the following subs for you:

=over

=item C<Point>

The C<< Point >> sub has many purposes.

Called with no parameters, it returns a L<type constraint object|Type::Tiny>
which can be used in C<isa> constraints, in C<signature_for> signatures, or
be tied to variables:

  use Marlin::Struct Point => [ 'x!', 'y!' ];
  use Marlin::Struct Rectangle => [
    'corner1!' => { isa => Point, coerce => true }
    'corner2!' => { isa => Point, coerce => true }
  ];
  
  tie( my $c, Point );
  $c = [ 1, 2 ];
  printf( "Coordinates: %f, %f.\n", $c->x, $c->y );
  
  signature_for draw_point => (
    positional => [
      Point,
      Str, { default => 'black' },
    ],
  );
  
  sub draw_point ( $point, $colour ) {
    ...;
  }

It can alternatively be given a hashref to create a new object of that class:

  my $c = Point { x => 1, y => 2 };

Note that it must be a hashref, not a hash/list.

  my $c = Point( x => 1, y => 2 );  # NOT THIS!

Or you can pass it an arrayref to create an object instead. If passing an
arrayref, then any required attributes can be given positionally, using
the order they were declared in.

  # These should all work!
  my $c = Point[ x => 1, y => 2 ];
  my $c = Point[ 1, y => 2 ];
  my $c = Point[ 2, x => 1 ];   # Weird, but okay
  my $c = Point[ 1, 2 ];

Lastly, you can call a few useful methods on it:

  # The underlying Perl package your objects are blessed into.
  # While this will be stable in a single process, it may vary from
  # one run of your program to another. It will be something like
  # "Marlin::Struct::__ANON__::_000123". You should never really
  # have to care exactly what string this returns!
  #
  my $real_class = Point->class;
  
  # An alternative way to construct a Point object.
  #
  my $c = Point->new( x => 1, y => 2 );
  
  # Point() returns a Type::Tiny object, so you can call any methods
  # defined in Type::Tiny on it.
  #
  if ( Point->check( $c ) ) {
    print "The value of \$c is a valid Point object!\n";
  }

=item C<< is_Point >>

A quick check to see if a value is a valid Point.

  if ( is_Point $c ) {
    ...;
  }

=item C<< assert_Point >>

Like C<is_Point>, but instead of returning a boolean, throws an exception if
the given value fails the check.

=item C<< to_Point >>

Can be passed a hashref or arrayref to convert it to a Point.

  # Simple case
  my $c = to_Point( { x => 1, y => 2 } );
  
  # Like Point[1, 2]
  my $c = to_Point( [ 1, 2 ] );
  
  # Can also be given an existing Point object, and just passes it through,
  # not really doing anything.
  my $c = to_Point( Point[1, 2] );
  
  # If passed something that cannot be converted into a Point object, just
  # passes it through, not really doing anything!
  my $c = to_Point( \*STDIN );
  
  # If you need to ensure that to_Point was successful...
  assert_Point my $c = to_Point( \*STDIN );

=back

Marlin::Struct is mostly suitable for defining helper classes that your
main public classes use internally which don't need any proper methods,
just a constructor and accessors. Classes defined using Marlin::Struct
will have stringification and arrayrefification defined for you, which is
mostly pretty sensible.

  use Marlin::Struct
    Point       => [ 'x!' => Num, 'y!' => Num ],
    ColourPoint => [ -isa => \'Point', colour => { default => 'red' } ];
  
  my $point1 = Point[1, 2];
  say "$point1";  # ==> Point[1, 2]
  
  my $point2 = ColourPoint[1, 2];
  say "$point2";  # ==> ColourPoint[1, 2, colour => "red"]

Stringification and arrayrefification will skip any attributes that have their
storage set to "PRIVATE".

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-marlin/issues>.

=head1 SEE ALSO

L<Marlin>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
