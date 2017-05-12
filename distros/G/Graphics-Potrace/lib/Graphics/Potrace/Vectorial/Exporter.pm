package Graphics::Potrace::Vectorial::Exporter;
$Graphics::Potrace::Vectorial::Exporter::VERSION = '0.76';
# ABSTRACT: vectorial exporter base class for Graphics::Potrace

use strict;
use warnings;
use Carp qw< croak >;
use English qw< -no_match_vars >;

use Moo;

has _fh => (
   is => 'rw',
   lazy => 1,
   predicate => 'has_fh',
   clearer   => 'clear_fh',
   builder => '_initialise_fh',
   init_arg => 'fh',
);

has file => (
   is => 'rw',
   lazy => 1,
   predicate => 'has_file',
   clearer   => 'clear_file',
   default => sub { croak 'no file defined' },
   trigger => sub { $_[0]->clear_fh() },
);

sub fh {
   my $self = shift;
   if (@_) {
      $self->clear_file();
      $self->_fh(@_);
   }
   return $self->_fh();
}

sub _initialise_fh {
   my $self = shift;
   croak 'neither fh nor file defined' unless $self->has_file();

   my $filename = $self->file();
   open my $fh, '>', $filename
      or croak "open('$filename'): $OS_ERROR";
   return $fh;
}

sub reset {
   my $self = shift;
   $self->clear_file();
   $self->clear_fh();
   return $self;
}

sub boundaries {
   my $self = shift;
   my ($width, $height) = (0, 0);
   for my $item (@_) {
      my ($w, $h) = ($item->width(), $item->height());
      $width = $w if $width < $w;
      $height = $h if $height < $h;
   }
   return ($width, $height);
}

# Create a copy, by default by using the same parameters. This method
# allows overriding this operation.
sub clone {
   my ($self) = @_;
   my %params = %$self;
   $params{fh} = $self->_fh() if $self->has_fh();
   return $self->new(%params);
}

# Create loop!!! This leaves derived classes the choice to implement either
# render() or save() as they see fit
sub render {
   my $self = shift;
   my $worker = ($self->has_fh() || $self->has_file()) ? $self->clone() : $self;
   $worker->file(\my $textual);
   $worker->save(@_);
   $worker->reset();
   return $textual;
}

sub save {
   my $self = shift;
   my $fh = $self->fh();
   print {$fh} $self->render(@_);
   return $self;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Graphics::Potrace::Vectorial::Exporter - vectorial exporter base class for Graphics::Potrace

=head1 VERSION

version 0.76

=head1 DESCRIPTION

This is a base class for building up vector exporters. One example
of using this base class is shipped directly in the distribution
as L<Graphics::Potrace::Vectorial::Svg>.

You only need override one of two methods in order to implement your
exporter: either L</render> or L</save>. Both receive a list of vectors
to be rendered, but are expected to
behave differently: the former should return a textual representation
of the exported stuff (e.g. text containing the full contents of a
SVG document), the latter is supposed to C<print> it to the internal
filehandle (collected via L</fh>).

In this class these two methods are both defined in terms of the other,
so that you can really override only one of them and get the other one
for free.

One additional method that you can find useful is L</boundaries>: it
will return the maximum width and height across the full list of
vectors, so that you can size the dimensions of your output representation
properly (e.g. set the C<width> and C<height> attributes in the C<svg>
outer element).

Exporters deriving from this base class accept two different parameters
for setting where the export can be performed: L</fh> and L</file>. So
you will always be able to call
L<Graphics::Potrace::Vectorial/create_exporter> like this:

   my $e1 = $vector->create_exporter($type, file => $filename);
   my $e2 = $vector->create_exporter($type, file => \my $text);
   my $e3 = $vector->create_exporter($type, fh   => $filehandle);

=head1 INTERFACE

=head2 B<< boundaries >>

   my ($width, $height) = $exporter->boundaries(@vectors);

This function returns the maximum width and height across the list of
provided vectors. These should be L<Graphics::Potrace::Vectorial> elements,
but anything providing both C<width> and C<height> methods will do.

=head2 B<< clear_file >>

   $exporter->clear_file();

Clear the value for the file, see L</file>.

=head2 B<< clear_fh >>

   $exporter->clear_fh();

Clear the value for the filehandle, see L</fh>.

=head2 B<< clone >>

   my $other_exporter = $exporter->clone();

Create a replica of the exporter object. It does this by calling
C<new> passing all the parameters already present, so you can override
it if your needs are more sophisticated. Used by the default provided
L</render> in order to avoid clobbering the main object.

=head2 B<< file >>

   $exporter->file($filename);  # some file in the filesystem
   $exporter->file(\my $text);  # a variable to save to
   my $current = $exporter->file();  # getter

Accessor to get/set a file where L</save> will save data. It can be
whatever L<perlfunc/open> accepts, e.g. a reference to a scalar.

=head2 B<< fh >>

   $exporter->fh($filehandle);
   my $fh = $exporter->fh();

Accessor to get/set a filehandle where L</save> will send data.

It is automatically (and lazily) populated when you call the I<get>ter,
so this will change what C<has_fh> will tell you (see L</has_fh> for
details).

Calling the I<get>ter will generate an exception if neither C<fh> nor
C<file> are set (you can test it with C<has_fh> or C<has_file>
respectively).

=head2 B<< has_file >>

   $exporter->has_file() and print "has it!\n";

Returns a boolean value depending on the immediate availability of
a file for L</save>. See also L</file>

=head2 B<< has_fh >>

   $exporter->has_fh() and print "has it!\n";

Returns a boolean value depending on the immediate availability of
a filehandle for L</save>.

Note that a filehandle might be available
to L</save> even though the value returned is false, because it might
be automatically populated in case there is a file (see L</has_file>
and L</file>). This means that C<has_fh> might return different values
depending on the evolution:

   my $e = Graphics::Potrace::Vectorial::Exporter->new();
   print "has it!\n" if $e->has_fh(); # does NOT print
   $e->file('/dev/null');
   print "has it!\n" if $e->has_fh(); # does NOT print, again
   my $fh = $e->fh(); # opens "file" and sets the fh
   print "has it!\n" if $e->has_fh(); # does print now!

=head2 B<< new >>

   my $e = Graphics::Potrace::Vectorial::Exporter->new(%args);

Constructor, input arguments can be C<file> and C<fh> passed in a key-value
style.

=head2 B<< render >>

   my $text = $exporter->render(@vectors);

Produce a rendering of the provided C<@vectors>, e.g. the SVG document
as a text in case of SVG. This method in this package uses L</save> to
do the heavy lifting, so you either have to override it or L</save>.

=head2 B<< reset >>

   $exporter->reset();

Clears both L</fh> and L</file> by calling respective clearers (i.e.
L</clear_fh> and L</clear_file>, respectively).

=head2 B<< save >>

   $exporter->save(@vectors);

Save a rendering of the provided C<@vectors> to L</fh>. This method in this
package uses L</render> to do the heavy lifting, so you either have to
override it or L</render>.

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
