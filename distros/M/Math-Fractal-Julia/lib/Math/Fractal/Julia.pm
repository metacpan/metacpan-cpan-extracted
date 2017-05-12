package Math::Fractal::Julia;
{
  $Math::Fractal::Julia::VERSION = '0.000003';
}
use strict;
use warnings;

# ABSTRACT: Calculate points in the Julia set

require XSLoader;
XSLoader::load( 'Math::Fractal::Julia', $Math::Fractal::Julia::VERSION );

sub new {
    my ( $class, %options ) = @_;

    my $julia = $class->_new();

    while ( my ( $key, $value ) = each %options ) {
        my $method = 'set_' . $key;
        if ( ref $value ) {
            $julia->$method(@$value);
        }
        else {
            $julia->$method($value);
        }
    }

    return $julia;
}

1;



=pod

=head1 NAME

Math::Fractal::Julia - Calculate points in the Julia set

=head1 VERSION

version 0.000003

=head1 SYNOPSIS

    use Math::Fractal::Julia;

    # Procedural usage:
    Math::Fractal::Julia->set_max_iter($iters);
    Math::Fractal::Julia->set_limit($limit);
    Math::Fractal::Julia->set_bounds( $x1, $y1, $x2, $y2, $w, $h );
    Math::Fractal::Julia->set_constant( $cx, $cy );
    for my $y ( 0 .. $h - 1 ) {
        for my $x ( 0 .. $w - 1 ) {
            my $iter = Math::Fractal::Julia->point( $x, $y );
        }
    }

    # Object Oriented usage:
    my $julia = Math::Fractal::Julia->new(%options);
    $julia->set_max_iter($iters);
    $julia->set_limit($limit);
    $julia->set_bounds( $x1, $y1, $x2, $y2, $w, $h );
    $julia->set_constant( $cx, $cy );
    for my $y ( 0 .. $h - 1 ) {
        for my $x ( 0 .. $w - 1 ) {
            my $iter = $julia->point( $x, $y );
        }
    }

=head1 DESCRIPTION

Calculates points in the set named after the French mathematician Gaston
Julia.

The procedural interface is based on that provided by
L<Math::Fractal::Mandelbrot>.

=head1 METHODS

=head2 new

=over 4

=item Arguments: %options?

=item Return value: A Math::Fractal::Julia object

=back

Creates a new Math::Fractal::Object.  If no options are provided, the
default values will be used.

=over 4

=item options

The C<options> hash may contain any or all of the following:

max_iter => $iters

limit => $limit

bounds => [ $x1, $x2, $y1, $y2, $width, $height ]

constant => [ $cx, $cy ]

=back

The default maximum number of iterations is 600.
The default limit is 5.
The default bounds is [-2.2, -1.1, 1.0, 1.1, 640, 480].
The default constant is [0.0, 0.0].

    my $julia = Math::Fractal::Julia->new();

    my $julia = Math::Fractal::Julia->new(%options);

    my $julia = Math::Fractal::Julia->new(
        max_iter => $iters,
        limit    => $limit,
        bounds   => [ $x1, $x2, $y1, $y2, $width, $height ],
        constant => [ $cx, $cy ],
    );

=head2 set_max_iter

=over 4

=item Arguments: $max

=item Return value: undefined

=back

Set the maximum number of iterations.  The default value is 600.

    Math::Fractal::Julia->set_max_iter($max);

    $julia->set_max_iter($max);

=head2 set_limit

=over 4

=item Arguments: $limit

=item Return value: undefined

=back

The default value is 5.

    Math::Fractal::Julia->set_limit($limit);

    $julia->set_limit($limit);

=head2 set_bounds

=over 4

=item Arguments: $x1, $y1, $x2, $y2, $width, $height

=item Return value: undefined

=back

Set the bounds of the set.  The first four values (C<$x1>, C<$y1>,
C<$x2>, C<$y2>) define a rectangle.  The remaining two (C<$width>,
C<$height>) define a viewport.

The default values are (-2.2, -1.1, 1.0, 1.1, 640, 480).

    Math::Fractal::Julia->set_bounds( $x1, $y1, $x2, $y2, $width, $height );

    $julia->set_bounds( $x1, $x2, $y1, $y2, $width, $height );

=head2 set_constant

=over 4

=item Arguments: $cx, $cy

=item Return value: undefined

=back

The default values are (0.0, 0.0).

    Math::Fractal::Julia->set_constant( $cx, $cy );

    $julia->set_constant( $cx, $cy );

=head2 point

=over 4

=item Arguments: $x, $y

=item Return value: The number of iterations needed to exceed the limit
or 0 if the the limit is not exceeded.

=back

This function translates the coordinates using the bounds and then
iterates.

    $iters = Math::Fractal::Julia->point( $x, $y );

    $iters = $julia->point( $x, $y );

=head1 CAVEATS

=over 4

=item *

This module is not thread-safe.

=item *

Any packages derived from C<Math::Fractal::Julia> will share the same
internal state when the procedural interface is used.

=back

=head1 SEE ALSO

=over 4

=item * L<Math::Fractal::Mandelbrot>

=item * L<Julia set|http://en.wikipedia.org/wiki/Julia_set>

=back

=head1 AUTHOR

Jeffrey T. Palmer <jtpalmer@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jeffrey T. Palmer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


