package Image::TextMode::Font;

use Moo;
use Types::Standard qw( Int ArrayRef );

has 'width' => ( is => 'rw', isa => Int, default => 0 );

has 'height' => ( is => 'rw', isa => Int, default => 0 );

has 'chars' => ( is => 'rw', isa => ArrayRef, default => sub { [] } );

=head1 NAME

Image::TextMode::Font - A base class for text mode fonts

=head1 DESCRIPTION

Represents a font in text mode. That is, an array of characters represented
by an array of byte scanlines.

=head1 ACCESSORS

=over 4

=item * width - The width of the font

=item * height - The height of the font

=item * chars - An array of array of scanline data

=back

=head1 METHODS

=head2 new( %args )

Creates a new font object.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2015 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
