package Image::TextMode::Palette::Atari;

use Moo;

extends 'Image::TextMode::Palette';

has '+colors' => (
    default => sub {
        [   [ 0x18, 0x70, 0xc0 ],    # bg
            [ 0x88, 0xd8, 0xf8 ],    # fg
        ];
    }
);

=head1 NAME

Image::TextMode::Palette::Atari - 2-color Atari palette

=head1 DESCRIPTION

This is the default ATASCII palette.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
