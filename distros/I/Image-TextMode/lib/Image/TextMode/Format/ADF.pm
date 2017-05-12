package Image::TextMode::Format::ADF;

use Moo;
use Types::Standard qw( HashRef );

extends 'Image::TextMode::Format', 'Image::TextMode::Canvas';

has 'header' =>
    ( is => 'rw', isa => HashRef, default => sub { { version => 1 } } );

sub extensions { return 'adf' }

=head1 NAME

Image::TextMode::Format::ADF - read and write ADF files

=head1 DESCRIPTION

ADF stands for "Artworx Data Format".

ADF file stucture:

    +------------+
    | Version    |
    +------------+
    | Palette    |
    +------------+
    | Font       |
    +------------+
    | Image Data |
    +------------+

=head1 ACCESSORS

=over 4

=item * header - A header hashref containing a version number

=back

=head1 METHODS

=head2 new( %args )

Creates a ADF instance.

=head2 extensions( )

Returns 'adf'.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2015 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
