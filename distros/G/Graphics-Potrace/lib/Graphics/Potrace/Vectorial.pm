package Graphics::Potrace::Vectorial;
$Graphics::Potrace::Vectorial::VERSION = '0.76';
# ABSTRACT: vectorial manipulator for Graphics::Potrace

use strict;
use Carp;

use Moo;

has list => (
   is => 'rw',
   isa => sub { return ref($_[0]) eq 'ARRAY' },
   lazy => 1,
   predicate => 'has_list',
   default => sub { [] },
);

has tree => (
   is => 'rw',
   isa => sub { return ref($_[0]) eq 'ARRAY' },
   lazy => 1,
   predicate => 'has_tree',
   default => sub { [] },
);

has width => (
   is => 'rw',
   lazy => 1,
   predicate => 'has_width',
   default => sub { 1 },
);

has height => (
   is => 'rw',
   lazy => 1,
   predicate => 'has_height',
   default => sub { 1 },
);

sub export {
   my $self = shift;
   $self->create_exporter(@_)->save($self);
   return $self;
} ## end sub save

sub render {
   my $self = shift;
   return $self->create_exporter(@_)->render($self);
}

sub create_exporter {
   my ($self, $type, @parameters) = @_;
   my $package = __PACKAGE__ . '::' . ucfirst($type);
   (my $filename = $package) =~ s{::}{/}mxsg;
   $filename .= '.pm';
   require $filename;
   return $package->new(@parameters);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Graphics::Potrace::Vectorial - vectorial manipulator for Graphics::Potrace

=head1 VERSION

version 0.76

=head1 SYNOPSIS

   # See Graphics::Potrace for ways of obtaining a G::P::Vectorial

   # Get a Svg representation in a scalar variable
   my $svg = $vector->render('Svg');

   # Save Encapsulated Postscript to file
   $vector->export(Eps => file => '/tmp/foo.eps');

   # Need to fiddle with the internals?
   my $width = $vector->width();
   my $height = $vector->height();
   for my $group (@{$vector->list()}) {
      printf "group, sign: %s\n", $group->{sign};
      my $curve = $group->{curve};
      for my $segment (@$curve) {
         printf "begin: %lf %lf\n", @{$segment->{begin}};
         if ($segment->{type} eq 'bezier') {
            printf "u: %lf %lf\n", @{$segment->{u}};
            printf "v: %lf %lf\n", @{$segment->{v}};
         }
         else { # type is corner
            printf "corner: %lf %lf\n", @{$segment->{corner}};
         }
         printf "end: %lf %lf\n", @{$segment->{end}};
      }
   }

   # Yes, you also have the tree representation, but you will have
   # to figure out how to use it! Documentation patches are welcome :)

=head1 DESCRIPTION

Vectorial representation and manipulator, obtained as the result of the
tracing activity. As such, L<Graphics::Potrace::Vectorial> objects should
be regarded mostly as read-only ones, but you can fiddle with them
if you need to.

One of the goals of having the vector representation will probably be
to save it into some format; the distribution comes with two default
exporters:

=over

=item *

L<Graphics::Potrace::Vectorial::Eps>, for Encapsulated Postscript

=item *

L<Graphics::Potrace::Vectorial::Svg>, for Standard Vectorial Graphics

=back

So, if you want to save the vector into SVG file C<foo.svg> you can
do this:

   $vector->export(Svg => file => 'foo.svg');

Both L<Graphics::Potrace::Vectorial::Eps> and
L<Graphics::Potrace::Vectorial::Svg> derive from
L<Graphics::Potrace::Vectorial::Exporter>; other exporters deriving from
it will support at least C<file> and C<fh> parameters in order to allow
you to do this:

   $vector->export($type, file => $filename);
   $vector->export($type, file => \my $text);
   $vector->export($type, fh   => $filehandle);

The first two will set a I<file> where to save data (in the second case it
will actually be a reference to a scalar for leveraging the internal
C<perlfunc/open>), the last will set a filehandle (e.g. a socket).

If you need a straight representation into a scalar, L</render> is probably
what you need:

   my $scalar = $vector->render($type);

As in the L</export> case, you have to at least provide the C<$type> of
rendering that you need.

=head1 INTERFACE

=head2 create_exporter

   my $exporter = $vector->create_exporter($type, @args);

Factory (class) method to generate an exporter of the suitable C<$type>.
C<@args> are passed over to the constructor of the relevant class.

The class is searched as C<Graphics::Potrace::Vectorial::$type> and will
arguably be a derivate class of L<Graphics::Potrace::Vectorial::Exporter>.

=head2 export

   $vector->export($type, @args);

Export a representation of the vector according to C<$type> and provided
C<@args>. This is equivalent to the following

   $vector->create_exporter($type, @args)->save($vector);

but more concise, see L</create_exporter> for details.

=head2 has_height

    $vector->has_height() and print "has it!\n";

Returns a boolean value depending on the availability of L</height>. It
is always true for objects created through the normal tracing process.

=head2 has_list

    $vector->has_list() and print "has it!\n";

Returns a boolean value depending on the availability of L</list>. It
is always true for objects created through the normal tracing process.

=head2 has_tree

    $vector->has_tree() and print "has it!\n";

Returns a boolean value depending on the availability of L</tree>. It
is always true for objects created through the normal tracing process.

=head2 has_width

    $vector->has_width() and print "has it!\n";

Returns a boolean value depending on the availability of L</width>. It
is always true for objects created through the normal tracing process.

=head2 height

   my $height = $vector->height();

Returns the height of the vector representation. This is set equal to the
height of the bitmap that led to the generation of the vector, so most
of the times it will be larger than what strictly needed.

=head2 list

Returns a list of I<curves> that - all together - form the whole vector.
See L<http://potrace.sourceforge.net/potracelib.pdf> for details on the
list representation.

=head2 render

   my $scalar = $vector->export($type, @args);

Generate a representation of the vector according to C<$type> and provided
C<@args>. This is equivalent to the following

   $vector->create_exporter($type, @args)->render($vector);

but more concise, see L</create_exporter> for details.

=head2 tree

Returns a tree of I<curves> that - all together - form the whole vector.
See L<http://potrace.sourceforge.net/potracelib.pdf> for details on the
tree representation.

=head2 width

   my $width = $vector->width();

Returns the width of the vector representation. This is set equal to the
width of the bitmap that led to the generation of the vector, so most
of the times it will be larger than what strictly needed.

=head1 AUTHOR

Flavio Poletti <polettix@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2015 by Flavio Poletti polettix@cpan.org.

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
