package Graphics::Primitive;
use Moose;

our $VERSION = '0.67';

__PACKAGE__->meta->make_immutable;

no Moose;
1;
__END__

=head1 NAME

Graphics::Primitive - Device and library agnostic graphic primitives

=cut

=head1 SYNOPSIS

Graphics::Primitive is a device and library agnostic system for creating
and manipulating various graphical elements such as Borders, Fonts, Paths
and the like.

    my $c = Graphics::Primitive::Component->new(
      background_color => Graphics::Color::RGB->new(
          red => 1, green => 0, blue => 0
      ),
      width => 500, height => 350,
      border => new Graphics::Primitive::Border->new( width => 5 )
    );

    my $driver = Graphics::Primitive::Driver::Cairo->new(format => 'SVG');

    $driver->prepare($c);
    $driver->finalize($c);
    $driver->draw($c);

    $driver->write($filename)

=head1 DESCRIPTION

Graphics::Primitive is library agnostic system for drawing things.

The idea is to allow you to create and manipulate graphical components and
then pass them off to a L<Driver|Graphics::Primitive::Driver> for actual
drawing.

=head1 CONCEPTS

The root object for Graphics::Primitive is the
L<Component|Graphics::Primitive::Component>.  Components contain all the
common elements that you'd expect: margins, padding, background color etc.

The next most important is the L<Container|Graphics::Primitive::Container>.
Containers are Components that can hold other Components.  Containers have all
the attributes and methods of a Component with the addition of the
I<layout_manager> attribute for us with L<Layout::Manager>.

Another important Component is the L<Canvas|Graphics::Primitive::Canvas>.
The Canvas differs from other components by being a container for various
L<Geometry::Primitive> objects.  This allows drawing of arbitrary shapes
that do not fit existing components.

=head1 DRAWING LIFECYCLE

After creating all your components, there is a lifecycle that allows them
to do their internal housekeeping to prepare for eventual drawing.  The
lifecycle is: B<prepare>, B<layout> and B<pack>.  Detailed explanation of
these methods can be found in L<Component|Graphics::Primitive::Component>.

=head1 PREPARATION

Graphics::Primitive::Component has a C<prepared> flag.  This flag is set as
part of the C<prepare> method (shocking, I know).  If this flag is set, then
subsequent calls to C<prepare> are ignored.  Containers also have a prepare
flag, but this flag is B<not> set when calling C<prepare>.  A Container's flag
should be set by the layout manager.  More information may be found with
L<Layout::Manager>.

=head1 INSPIRATION

Most of the concepts that you'll find in Graphics::Primitive are inspired by
L<Cairo|http://cairographics.org>'s API and
L<CSS|http://www.w3.org/Style/CSS/>'s box model.

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 CONTRIBUTORS

Florian Ragwitz

=head1 ACKNOWLEDGEMENTS

Many of the ideas here come from my experience using the Cairo library.

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 by Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
