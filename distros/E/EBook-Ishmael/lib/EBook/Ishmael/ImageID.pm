package EBook::Ishmael::ImageID;
use 5.016;
our $VERSION = '1.05';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(image_id image_size);

use List::Util qw(max);

use XML::LibXML;

my %MAGIC = (
	pack("C*", 0xff, 0xd8, 0xff)                               => 'jpg',
	pack("C*", 0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a) => 'png',
	pack("C*", 0x47, 0x49, 0x46, 0x38)                         => 'gif',
	pack("C*", 0x52, 0x49, 0x46, 0x46)                         => 'webp',
	pack("C*", 0x42, 0x4d)                                     => 'bmp',
	pack("C*", 0x49, 0x49)                                     => 'tif',
	pack("C*", 0x4d, 0x4d)                                     => 'tif',
);

# File formats that do not have magic bytes, use a subroutine instead.
my %NONMAGIC = (
	'svg' => sub {
		substr(${ $_[0] }, 0, 1024) =~ /<\s*svg[^<>]*>/
	},
);

# This function may not support many image formats as it was designed for
# getting image sizes for CHM files to determine the cover image. CHMs
# primarily use GIFs.
# TODO: Add tif support
# TODO: Add webp support (probably never)
my %SIZE = (
	# size stored as two BE ushorts in the SOF0 marker, at offset 5.
	'jpg' => sub {

		my $ref = shift;

		my $len = length $$ref;

		my $p = 2;

		my $sof = join ' ', 0xff, 0xc0;

		while ($p < $len) {

			my $id = join ' ', unpack "CC", substr $$ref, $p, 2;
			$p += 2;
			my $mlen = unpack "n", substr $$ref, $p, 2;

			unless ($id eq $sof) {
				$p += $mlen;
				next;
			}

			my ($y, $x) = unpack "nn", substr $$ref, $p + 3, 4;

			return [ $x, $y ];

		}

		return undef;

	},
	# size stored as two BE ulongs at offset 16
	'png' => sub {

		my $ref = shift;

		return undef unless length $$ref > 24;

		my ($x, $y) = unpack "N N", substr $$ref, 16, 8;

		return [ $x, $y ];

	},
	# size stored as two LE ushorts at offset 6
	'gif' => sub {

		my $ref = shift;

		return undef unless length $$ref > 10;

		my ($x, $y) = unpack "v v", substr $$ref, 6, 4;

		return [ $x, $y ];

	},
	# size storage depends on header. For an OS header, two LE ushorts at
	# offset 18. For Windows, two LE signed longs at offset 18.
	'bmp' => sub {

		my $ref = shift;

		return undef unless length $$ref > 24;

		my $dbisize = unpack "V", substr $$ref, 14, 4;

		my ($x, $y);

		# OS
		if ($dbisize == 16) {
			($x, $y) = unpack "v v", substr $$ref, 18, 4;
		# Win
		} else {
			($x, $y) = unpack "(ll)<", substr $$ref, 18, 8;
			return undef if $x < 0 or $y < 0;
		}

		return [ $x, $y ];

	},
	# Get width and height attributes of root node.
	'svg' => sub {

		my $ref = shift;

		my $dom;

		eval {
			$dom = XML::LibXML->load_xml(string => $ref);
			1;
		} or return undef;

		my $svg = $dom->documentElement;

		my $x = $svg->getAttribute('width') or return undef;
		my $y = $svg->getAttribute('height') or return undef;

		return [ $x, $y ];

	},
);

sub image_id {

	my $ref = shift;

	my $sublen = max map { length } keys %MAGIC;

	my $mag = substr $$ref, 0, $sublen;

	for my $m (keys %MAGIC) {
		return $MAGIC{ $m } if $mag =~ /^\Q$m\E/;
	}

	for my $nm (keys %NONMAGIC) {
		return $nm if $NONMAGIC{ $nm }->($ref);
	}

	return undef;

}

sub image_size {

	my $ref = shift;
	my $fmt = shift // image_id($ref);

	unless (defined $fmt) {
		die "Could not determine image data format\n";
	}

	unless (exists $SIZE{ $fmt }) {
		return undef;
	}

	return $SIZE{ $fmt }->($ref);

}

1;

=head1 NAME

EBook::Ishmael::ImageID - Identify image data format

=head1 SYNOPSIS

  use EBook::Ishmael::ImageID;

  my $format = image_id($dataref);

=head1 DESCRIPTION

B<EBook::Ishmael::ImageID> is a module that provides the C<image_id()>
subroutine, which identifies the image format of a given buffer. This is
developer documentation, for L<ishmael> user documentation you should consult
its manual.

Currently, the following formats are supported:

=over 4

=item jpg

=item png

=item gif

=item webp

=item bmp

=item tif

=item svg

=back

=head1 SUBROUTINES

=over 4

=item $f = image_id($dataref)

Returns a string of the image format of the given image buffer. C<$dataref>
must be a scalar ref. Returns C<undef> if the image's format could not be
identified.

=item [$x, $y] = image_size($dataref, [$fmt])

Returns an C<$x>/C<$y> pair representing the image data's size. C<$fmt> is an
optional argument specifying the format to use for the image data. If not
specified, C<image_size> will identify the format itself. If the image size
could not be determined, returns C<undef>.

This subroutine does not support the following formats (yet):

=over 4

=item webp

=item tif

=back

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg Page|https://codeberg.org/1-1sam/ishmael>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=cut
