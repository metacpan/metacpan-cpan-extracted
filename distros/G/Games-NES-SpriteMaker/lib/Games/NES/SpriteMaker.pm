package Games::NES::SpriteMaker;
BEGIN {
  $Games::NES::SpriteMaker::AUTHORITY = 'cpan:DOY';
}
$Games::NES::SpriteMaker::VERSION = '0.02';
use strict;
use warnings;
# ABSTRACT: manipulate PNM files and generate NES sprite data from them

use Exporter 'import';
our @EXPORT_OK = ('image_to_sprite');

use Image::PNM;



sub image_to_sprite {
    my ($data, %opts) = @_;

    $opts{rom_size} ||= 8192;

    my $image = Image::PNM->new($data);
    if ($image->width % 8 || $image->height % 8) {
        die "Sprite collections must be tiles of 8x8 sprites (not "
          . $image->width . "x" . $image->height . ")";
    }
    my %colors = _get_palette_colors($image);

    my $sprite_x = $image->width / 8;
    my $sprite_y = $image->height / 8;

    my $bytes = '';
    for my $base_y (0..$sprite_y-1) {
        for my $base_x (0..$sprite_x-1) {
            for my $pixel_y ($base_y*8..$base_y*8 + 7) {
                my $bits;
                for my $pixel_x ($base_x*8..$base_x*8 + 7) {
                    my $pixel = $image->raw_pixel($pixel_y, $pixel_x);
                    my $pixel_value = $colors{_color_key($pixel)};
                    $bits .= $pixel_value & 0x01 ? "1" : "0";
                }
                $bytes .= pack("C", oct("0b$bits"));
            }
            for my $pixel_y ($base_y*8..$base_y*8 + 7) {
                my $bits;
                for my $pixel_x ($base_x*8..$base_x*8 + 7) {
                    my $pixel = $image->raw_pixel($pixel_y, $pixel_x);
                    my $pixel_value = $colors{_color_key($pixel)};
                    $bits .= $pixel_value & 0x02 ? "1" : "0";
                }
                $bytes .= pack("C", oct("0b$bits"));
            }
        }
    }

    return $bytes . ("\x00" x ($opts{rom_size} - length($bytes)));
}

sub _get_palette_colors {
    my ($image) = @_;

    my $max = $image->max_pixel_value;
    my %unique_values = ("$max;$max;$max" => 0);
    my $idx = 1;
    for my $row (0..$image->height - 1) {
        for my $col (0..$image->width - 1) {
            my $pixel = $image->raw_pixel($row, $col);
            $unique_values{_color_key($pixel)} = $idx++
                unless defined $unique_values{_color_key($pixel)};
        }
    }

    if ($idx > 4) {
        die "Sprites can only use four colors";
    }

    return %unique_values;
}

sub _color_key {
    my ($pixel) = @_;
    return "$pixel->[0];$pixel->[1];$pixel->[2]";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::NES::SpriteMaker - manipulate PNM files and generate NES sprite data from them

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Games::NES::SpriteMaker 'image_to_sprite';

  open my $fh, '>', 'sprites.chr';
  my $chr = image_to_sprite('spritemap.pgm');
  $fh->print($chr);
  $fh->close;

=head1 DESCRIPTION

This module contains useful functions for manipulating images in the PNM format
in order to create and modify sprite data (CHR-ROM banks) in NES roms. The idea
is that drawing sprites is much easier in a real graphics editor, and then you
can save the image as a .pbm/.pgm/.ppm file and convert it into sprite data
directly, rather than having to edit sprites in a hex editor.

Right now, the capabilities are pretty limited, but I'm open to adding more
functionality as it becomes useful.

=head1 FUNCTIONS

=head2 image_to_sprite($data, %opts)

Converts PNM data to CHR-ROM data. C<$data> can either be a filename or a
scalar reference which is a reference to a string containing PNM-format data.
C<%opts> is a hash of options for how to generate the data. Currently the only
option is C<rom_size>, which determines the size of the .chr file to generate.
It defaults to C<8192>.

=head1 BUGS

Please report any bugs to GitHub Issues at
L<https://github.com/doy/games-nes-spritemaker/issues>.

=head1 SEE ALSO

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Games::NES::SpriteMaker

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Games-NES-SpriteMaker>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-NES-SpriteMaker>

=item * Github

L<https://github.com/doy/games-nes-spritemaker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-NES-SpriteMaker>

=back

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
