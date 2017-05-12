package Graphics::Potrace::Raster::Packed;
$Graphics::Potrace::Raster::Packed::VERSION = '0.76';
# ABSTRACT: importer of packed rasters for Graphics::Potrace

use strict;
use warnings;
use Carp;
use English qw( -no_match_vars );

use Moo;

extends 'Graphics::Potrace::Raster::Importer';

sub load_data {
   my ($self, $reference) = shift;
   my $bitmap = $self->target();
   $bitmap->reset();
   $bitmap->real_bitmap($reference->{'map'});
   $bitmap->dy($reference->{dy});
   $bitmap->width($reference->{width});
   $bitmap->height($reference->{height});
   return $bitmap;
}

sub load_handle {
   croak __PACKAGE__ . ' does not support load_handle';
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Graphics::Potrace::Raster::Packed - importer of packed rasters for Graphics::Potrace

=head1 VERSION

version 0.76

=head1 DESCRIPTION

This class is an importer for L<Graphics::Potrace>. It derives from
L<Graphics::Potrace::Raster::Importer>, so see it for generic methods.
In particular, this class overrides L</load_handle> in order to
provide means to load a raster image from a packed version of some
other raster image (see L<Graphics::Potrace::Raster/packed>).

=head1 INTERFACE

Only method L<Graphics::Potrace::Raster::Imported/load_data> is
supported (and C<load> whereas it calls C<load_data>). Attempts to
call L<Graphics::Potrace::Raster::Imported/load_handle> will fail.

=begin ignored

=head2 load_data

=head2 load_handle

=end ignored

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
