package Image::TextMode::Palette::VGA;

use Moo;

extends 'Image::TextMode::Palette';

has '+colors' => (
    default => sub {
        [   [ 0x00, 0x00, 0x00 ],
            [ 0x00, 0x00, 0xaa ],
            [ 0x00, 0xaa, 0x00 ],
            [ 0x00, 0xaa, 0xaa ],
            [ 0xaa, 0x00, 0x00 ],
            [ 0xaa, 0x00, 0xaa ],
            [ 0xaa, 0x55, 0x00 ],
            [ 0xaa, 0xaa, 0xaa ],
            [ 0x55, 0x55, 0x55 ],
            [ 0x55, 0x55, 0xff ],
            [ 0x55, 0xff, 0x55 ],
            [ 0x55, 0xff, 0xff ],
            [ 0xff, 0x55, 0x55 ],
            [ 0xff, 0x55, 0xff ],
            [ 0xff, 0xff, 0x55 ],
            [ 0xff, 0xff, 0xff ],
        ];
    }
);

=head1 NAME

Image::TextMode::Palette::VGA - 16-color VGA palette

=head1 DESCRIPTION

This is the default VGA palette.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2015 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
