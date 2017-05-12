package Imager::Search::Driver::HTML24;

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





#####################################################################
# Imager::Search::Driver Methods

sub image_string {
	my $self   = shift;
	my $imager = shift;
	my $string = '';
	my $height = $imager->getheight;
	foreach my $row ( 0 .. $height - 1 ) {
		# Get the string for the row
		$string .= join('',
			map { sprintf( "#%02X%02X%02X", ($_->rgba)[0..2] ) }
			$imager->getscanline( y => $row )
		);
	}
	return \$string;
}

sub pattern_lines {
	my $self   = shift;
	my $imager = shift;
	my @lines  = ();
	my $height = $imager->getheight;	
	foreach my $row ( 0 .. $height - 1 ) {
		$lines[$row] = $self->pattern_line($imager, $row);
	}
	return \@lines;
}

sub pattern_line {
	my ($self, $imager, $row) = @_;

	# Get the colour array
	my $line = '';
	my $this = '';
	my $more = 1;
	foreach my $color ( $imager->getscanline( y => $row ) ) {
		my ($r, $g, $b, undef) = $color->rgba;
		my $string = sprintf("#%02X%02X%02X", $r, $g, $b);
		if ( $this eq $string ) {
			$more++;
			next;
		}
		$line .= ($more > 1) ? "(?:$this){$more}" : $this; # if $this; (conveniently works without the if) :)
		$more  = 1;
		$this  = $string;
	}
	$line .= ($more > 1) ? "(?:$this){$more}" : $this;

	return $line;
}

sub pattern_regexp {
	my $self    = shift;
	my $pattern = shift;
	my $width   = shift;

	# Assemble the regular expression
	my $pixels  = $width - $pattern->width;
	my $newline = '.{' . ($pixels * 7) . '}';
	my $lines   = $pattern->lines;
	my $string  = join( $newline, @$lines );

	return qr/$string/si;
}

sub match_object {
	my $self    = shift;
	my $image   = shift;
	my $pattern = shift;
	my $byte    = shift;
	my $pixel   = $byte / 7;

	# If the pixel position isn't an integer we matched
	# at a position that is not a pixel boundary, and thus
	# this match is a false positive. Shortcut to fail.
	unless ( $pixel == int($pixel) ) {
		return; # undef or null list
	}

	# Calculate the basic geometry of the match
	my $top    = int( $pixel / $image->width );
	my $left   = $pixel % $image->width;

	# If the match overlaps the newline boundary or falls off the bottom
	# of the image, this is also a false positive. Shortcut to fail.
	if ( $left > $image->width - $pattern->width ) {
		return; # undef or null list
	}
	if ( $top > $image->height - $pattern->height ) {
		return; # undef or null list
	}

	# This is a legitimate match.
	# Convert to a match object and return.
	return Imager::Search::Match->new(
		name   => $pattern->name,
		top    => $top,
		left   => $left,
		height => $pattern->height,
		width  => $pattern->width,
	);
}

1;

=pod

=head1 NAME

Imager::Search::Driver::HTML24 - Simple Imager::Search reference driver

=head1 DESCRIPTION

B<Imager::Search::Driver::HTML24> is a simple reference driver for
L<Imager::Search>.

It uses a HTML color string (such as #RRGGBB) for each pixel, providing
both a simple text expression of the colour, as well as a hash pixel
separator.

This colour pattern provides for 24-bit (3 channel, 8-bits per challel)
colour depth, suitable for use with the 24-bit L<Imager>.

Search patterns are compressed, so that a horizontal stream of identical
pixels are represented as a single match group.

=head1 SUPPORT

See the SUPPORT section of the main L<Imager::Search> module.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
