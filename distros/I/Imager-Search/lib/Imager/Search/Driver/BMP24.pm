package Imager::Search::Driver::BMP24;

# Basic search driver implemented in terms of 8-bit
# HTML-style strings ( #003399 )

use 5.006;
use strict;
use Imager::Search::Match  ();
use Imager::Search::Driver ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.01';
	@ISA     = 'Imager::Search::Driver';
}

use constant HEADER => 54;





#####################################################################
# Imager::Search::Driver Methods

sub image_string {
	my $self   = shift;
	my $imager = shift;
	my $data   = '';
	$imager->write(
		data => \$data,
		type => 'bmp',
	) or die "Failed to generate image string";
	return \$data;
}

sub pattern_lines {
	my $self   = shift;
	my $imager = shift;
	my $data   = '';
	$imager->write(
		data => \$data,
		type => 'bmp',
	) or die "Failed to generate bmp image";

	# The bmp will contain the raw scanline data we want in
	# a series of byte ranges. Capture each range and quotemeta
	# the raw bytes.
	my $pixels = $imager->getwidth;
	my $range  = $pixels * 3;
	my $width  = $range + (-$range % 4);
	return [
		map { quotemeta substr( $data, $_, $range ) }
		map { HEADER + $_ * $width }
		( 0 .. $imager->getheight - 1 )
	];
}

sub pattern_regexp {
	my $self    = shift;
	my $pattern = shift;
	my $width   = shift;

	# Each BMP scan line comes in groups of 4-byte dwords.
	# As a result, each line contains an amount of useless extra
	# bytes needed to round it up to a multiple of 4 bytes.
	my $junk    = ($width * -3) % 4;
	my $pixels  = $width - $pattern->width;
	my $newline = '.{' . ($pixels * 3 + $junk) . '}';

	# Assemble the regexp
	my $lines   = $pattern->lines;
	my $string  = join( $newline, @$lines );

	return qr/$string/s;
}

sub match_object {
	my $self    = shift;
	my $image   = shift;
	my $pattern = shift;
	my $byte    = shift;

	# Remove the delta from the header
	$byte -= HEADER;

	# If we accidentally matched somewhere in header, we need
	# to discard the match. Shortcut to fail.
	unless ( $byte >= 0 ) {
		return; # undef or null list
	}

	# The bytewidth of a line is pixel width
	# multiplied by three, plus one for the newline.
	my $pixel_width = $image->width;
	my $byte_junk   = ($pixel_width * -3) % 4;
	my $byte_width  = $pixel_width * 3 + $byte_junk;

	# Find the column for the match.
	# If the column isn't an integer we matched at a position that is
	# not a pixel boundary, and thus this match is a false positive.
	# Shortcut to fail.
	my $pixel_left = ($byte % $byte_width) / 3;
	unless ( $pixel_left == int($pixel_left) ) {
		return; # undef or null list
	}

	# If the match overlaps the newline boundary this is also a
	# false positive. Shortcut to fail.
	if ( $pixel_left > $image->width - $pattern->width ) {
		return; # undef or null list
	}

	# The match position represents the bottom row.
	# If the match falls off the top of the image this is also
	# a false positive. Shortcut to fail.
	my $pixel_bottom = $image->height - int($byte / $byte_width) - 1;
	if ( $pixel_bottom < $pattern->height - 1 ) {
		return; # undef or null list
	}

	# This is a legitimate match.
	# Convert to a match object and return.
	return Imager::Search::Match->new(
		name   => $pattern->name,
		top    => $pixel_bottom - $pattern->height + 1,
		left   => $pixel_left,
		height => $pattern->height,
		width  => $pattern->width,
	);
}

1;

=pod

=head1 NAME

Imager::Search::Driver::BMP24 - Imager::Search driver based on 24-bit BMP

=head1 DESCRIPTION

B<Imager::Search::Driver::BMP24> is a simple default driver for L<Imager::Search>.

It generates a search regular expression that can scan a Windows BMP
directly, taking advantage of fast underlying C code that generates these
files.

For a 1024x768 screen grab, the result is that the BMP24 driver is 50-100
times faster to generate a search image compated to the HTML24 driver.

=head1 SUPPORT

See the SUPPORT section of the main L<Imager::Search> module.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
