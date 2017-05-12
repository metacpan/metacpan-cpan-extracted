#
# Image::BioChrome
#
# BioChrome is designed to dynamically generate gif files by rewriting the
# global color table that a gif files contains
#
# Author: Simon Matthews <sam@tt2.com>
#
# Copyright (C) 2003 Simon Matthews.  All Rights Reserved.
#
# This module is free software; you can distribute it and/or modify is under
# the same terms as Perl itself.
#

package Image::BioChrome;

use Data::Dumper;

use strict;

# required for mkpath
use File::Path;
use File::Copy;
use File::Temp qw/ tempfile /;
use File::Basename;

use vars qw($VERSION $DEBUG $MOD $VERBOSE $EXTN_ONLY);

$VERSION = sprintf("%d.%02d", q$Revision: 1.16 $ =~ /(\d+)\.(\d+)/);

$MOD = 'Image::BioChrome';

$DEBUG |= 0;
$VERBOSE |= 0;
$EXTN_ONLY |= 0;

my $file_types = [ qw( gif ) ];


#============================================================================
#
# new(filename) 
#
#============================================================================

sub new {
	my $class = shift;
	my $file = shift;
	
	unless ($file) {
		warn "$MOD: No file\n" if $VERBOSE || $DEBUG;
		die "No file\n";
		return;
	};

	my $self = { preserve => 1 };
	
	unless (-f $file) {
		warn "$MOD: File not found: $file\n" if $VERBOSE || $DEBUG;
		die "File not found: $file\n";
		return;
	}

	# default the image type
	$self->{ type } = '';

	# save the full name of the source file
	$self->{ src_file } = $file;

	# bless our self into the class
	bless $self, $class;

	# read the file
	$self->_read_file();

	# validate the type of the file
	$self->_valid_type();

	return $self;
}


#============================================================================
#
# colors 
#
#============================================================================

sub colors {
	my $self = shift;

	# process the color arguments
	$self->_color_args('colors', @_);
	delete $self->{ alphas };
}


#============================================================================
#
# alphas 
#
#============================================================================

sub alphas {
	my $self = shift;

	# process the alpha arguments
	$self->_color_args('alphas', @_);
	delete $self->{ colors };
}


#============================================================================
#
# percents 
#
#============================================================================

sub percents {
	my $self = shift;

	print STDERR "percents called\n" if $DEBUG;

	# must have a valid type
	return unless $self->{ type };

	# what is the method
	my $method = "_$self->{ type }_all_colors";

	print STDERR "method [$method]\n" if $DEBUG;

	# calling the method
	$self->$method('_calc_percent',@_);

}


#============================================================================
#
# write_file 
#
#============================================================================

sub write_file {
	my $self = shift;
	my $file = shift || return;

	print STDERR "$MOD: write_file [$file]\n" if $DEBUG;

	# validate the filename 


	# process our internal data to re-write the colors
	$self->_color() if $self->{ colors };
	$self->_alpha() if $self->{ alphas };

	# the default is to copy the image data
	$self->{ output_data } = $self->{ data } unless $self->{ output_data };

	my $base = dirname($file);
	
	# check that the directory exists
	unless (-d $base) {

		# eval this as problems in directory creation can cause a die
		eval {
			mkpath($base) || die "Failed to make directory: $base\n";
		};

		die "Failed to make directory\n" if $@;
	}

	# create a temporary file
	my($fh, $temp) = tempfile();

	binmode($fh);
	print $fh $self->{ output_data };
	close($fh);

	# tidy out internal state
	delete $self->{ output_data };

	# move the temporary file to the destination
	move($temp, $file) || do {
		unlink($temp);
		die "Failed to move temporary file\n";
	};


	if ($self->{ preserve }) {

		my $uid  = $self->{ file }->{ uid };
		my $gid  = $self->{ file }->{ gid };
		my $mode = $self->{ file }->{ mode };

	    chown($uid, $gid, $file) || do {
			warn "chown($file): $!\n" if $VERBOSE;
		};

	    chmod($mode, $file) || do {
			warn "chmod($file): $!\n" if $VERBOSE;
		};
	}

	return;
}


#============================================================================
#
# reset_file
#
# reset the file to it's original state
#
#============================================================================

sub reset_file {
	my $self = shift;

	warn "reset_file is deprecated\n";
	# file now automatically reset do nothing
	# $self->_read_file();
}


#============================================================================
#============================================================================
#
# INTERNAL METHODS BELOW
#
#============================================================================
#============================================================================

#============================================================================
#
# _read_file 
#
#============================================================================

sub _read_file {
	my $self = shift;

	my $file = $self->{ src_file };
	my $part;

	$self->{ data } = '';

	local *FILE;

	open(FILE, $file) || do {
		die "Failed to open file\n";
		print STDERR "$MOD: failed to open $file: $!\n";
		return;
	};

    # stat the file so we can preserve mode and ownership
    my ($mode, $uid, $gid, $time);
	
	(undef, undef, $mode, undef, $uid, $gid, undef, undef, undef, $time, undef,
	 undef, undef)  = stat($file);

	# save the file info
	$self->{ file }->{ mode } = $mode;
	$self->{ file }->{ uid }  = $uid;
	$self->{ file }->{ gid }  = $gid;
	$self->{ file }->{ time } = $time;
    
	binmode(FILE);

	while(read FILE, $part, 1024) {
		$self->{ data } .= $part;
	}

	close(FILE);
}

#============================================================================
#
# _color_args
#
# process the arguments to the colors or alphas method and stores the
# data in our self
#
#============================================================================

sub _color_args {
	my $self = shift;
	my $type = shift;
	my @parm = @_;
	my @cols;

	# ensure any previous colors are removed
	$self->{ $type } = undef;

	# if we have more than one argument we assume them to be the colors
	if ($#parm) {
		@cols = @parm;
	} else {
		# we only have one arg
		my $col = $parm[0];

		# the arg is a scalar
		unless (ref($col)) {

			# safety checks on the color string
			$col =~ s/^_+//;
			$col =~ s/_{2,}/_/g;

			@cols = split(/[^0-9a-f#]+/, lc $col);

		} elsif (ref($col) eq 'ARRAY') {
			# dereference the array
			@cols = @$col;
		} else {
			die "REF: no known\n";
		}
	}

	# check each color and only add it to the colors if it is valid
	foreach (@cols) {
		if (my $col = $self->_valid_color($_)) {
			push(@{ $self->{ $type } }, $col );
		} else {
			warn "Invalid color [$_]\n" if $VERBOSE;
		}
	}

}


#============================================================================
#
# _valid_color
#
# retuns the color if it is valid otherwise undef.  Colors will be retuned
# without any leading # character
#
#============================================================================

sub _valid_color {
	my $self  = shift;
	my $color = shift;

	if ($color =~ /^#?([0-9a-f]{6})$/i) {
		return $1;
	}

	return;
}

#============================================================================
#
# _split_colors
#
# Splits a color string into an ARRAY ref
#
#============================================================================

sub _split_colors {
	my $self = shift;
	my $colors = shift;

	# some safety checks on the color string
	$colors =~ s/^_+//;
	$colors =~ s/_{2,}/_/g;

	my @colors = split(/_/,$colors);

	return \@colors;
}


#============================================================================
#
# _gif_all_colors
#
# Process the color palette in a gif file and perform some calculation on
# each color in the palette
#
#============================================================================

sub _gif_all_colors {
	my $self = shift;
	my $calc = shift || return;

	print STDERR "gif all colors [$calc] called\n" if $DEBUG;

	# get the gif file data
	my $gif = $self->{ data };

	my $pf = vec($gif, 10, 8);

	# Packed field format
	#
	# 10000000 Global Color Table
	# 01110000 Color Resolution
	# 00001000 Sorted
	# 00000111 Size of Global Color Table

	# check that the gif has a global color map for us to change
	if ($pf & 128) {

		# has a color table so lets get it's size
		my $cts = $pf & 7;

		# the actual number of colors is the cts number + 1 to the 
		# power of two
		$cts = 2 ** ($cts + 1);

		print STDERR "Color Table Size is [$cts]\n" if $DEBUG;

		my $cc = 0;

		# get each color from the map and write it into the gct
		# until we have no more colors or we have run out of space
		while ($cc < $cts) {

			# get the red green and blue parts of the color
			my $r = vec($gif, (($cc * 3) + 13),8);
			my $g = vec($gif, (($cc * 3) + 14),8);
			my $b = vec($gif, (($cc * 3) + 15),8);

			# run the calculation function on the color
			my ($rr, $rg, $rb) = $self->$calc($r, $g, $b, @_);

			# put the colors back into the image
			vec($gif, (($cc * 3) + 13), 8) = int($rr);
			vec($gif, (($cc * 3) + 14), 8) = int($rg);
			vec($gif, (($cc * 3) + 15), 8) = int($rb);

			# increment the color counter
			$cc++;
		}
	}

	# save the gif data ready for output by write file
	$self->{ output_data } = $gif;
    return;
}

#============================================================================
#
# _color
#
#============================================================================

sub _color {
	my $self = shift;

	return unless $self->{ type };

	my $method = '_' . $self->{ type } . '_colorise';

	$self->$method();
}


#============================================================================
#
# _alpha
#
#============================================================================

sub _alpha {
	my $self = shift;

	return unless $self->{ type };

	my $method = '_' . $self->{ type } . '_alpha';

	$self->$method();
}


#==============================================================================
#
# _calc_percent($r, $g, $b, $percent_r, $percent_g, $percent_b)
#
#==============================================================================

sub _calc_percent {
	my $self = shift;
	my $c;
	my $p;
	my $r;

	# get the args
	($c->{ r }, $c->{ g }, $c->{ b }, $p->{ r }, $p->{ g }, $p->{ b }) = @_;

	foreach (qw[r g b]) {

		$p->{ $_ } = 100 unless defined $p->{ $_ };

		# do the calculation
		$r->{ $_ } = $c->{ $_ } * ($p->{ $_ } / 100);

		$r->{ $_ } = 255 if $r->{ $_ } > 255;
		$r->{ $_ } = 0 if $r->{ $_ } < 0;

	}

	return ($r->{r}, $r->{g}, $r->{b});
}


#==============================================================================
#
# _gif_alpha()
#
# changes the colors in a gif file based on the alpha channel values of the
# existing colors.  This is used to recolor greyscale images into more
# palettable graphics
#
#==============================================================================

sub _gif_alpha {
	my $self = shift;

	my $alphas = $self->{ alphas } || return;

	# get the gif file data
	my $gif = $self->{ data };

    my ($color1, $color2, $color3, $color4) = @$alphas;

	my $pf = vec($gif, 10, 8);

	my ($r1, $g1, $b1) = make_rgb($color1);
	my ($r2, $g2, $b2) = make_rgb($color2 || $color1);
	my ($r3, $g3, $b3) = make_rgb($color3) if $color3;
	my ($r4, $g4, $b4) = make_rgb($color4) if $color4;

	# Packed field format
	#
	# 10000000 Global Color Table
	# 01110000 Color Resolution
	# 00001000 Sorted
	# 00000111 Size of Global Color Table

	# check that the gif has a global color map for us to change
	if ($pf & 128) {
		# has a color table
		my $cts = $pf & 7;

		# the actual number of colors is the cts number + 1 to the 
		# power of two
		$cts = 2 ** ($cts + 1);

		print STDERR "Color Table Size is [$cts]\n" if $DEBUG;

		my $cc = 0;
		# get each color from the map and write it into the gct
		# until we have no more colors or we have run out of space
		while ($cc < $cts) {

			my $r = vec($gif, (($cc * 3) + 13),8);
			my $g = vec($gif, (($cc * 3) + 14),8);
			my $b = vec($gif, (($cc * 3) + 15),8);

			# calculate the colors
			my $pc1bg = $r / 255;
			my $pc1fg = abs(255 - $r) / 255;

			print STDERR "pc1 [$pc1fg] pc2 [$pc1bg]\n" if $DEBUG;

			my $rr = ($r1 * $pc1fg) + ($r2 * $pc1bg);
			my $rg = ($g1 * $pc1fg) + ($g2 * $pc1bg);
			my $rb = ($b1 * $pc1fg) + ($b2 * $pc1bg);

			if ($color3) {
				my $pc2fg = $g / 255;
				my $pc2bg = abs(255 - $g) / 255;

				$rr = ($rr * $pc2bg) + ($r3 * $pc2fg);
				$rg = ($rg * $pc2bg) + ($g3 * $pc2fg);
				$rb = ($rb * $pc2bg) + ($b3 * $pc2fg);
			}

			if ($color4) {
				my $pc2fg = $b / 255;
				my $pc2bg = abs(255 - $b) / 255;

				$rr = ($rr * $pc2bg) + ($r4 * $pc2fg);
				$rg = ($rg * $pc2bg) + ($g4 * $pc2fg);
				$rb = ($rb * $pc2bg) + ($b4 * $pc2fg);
			}

			# print "r [$r] g [$g] b [$b]\n";

			# put the colors back into the image
			vec($gif, (($cc * 3) + 13), 8) = int($rr);
			vec($gif, (($cc * 3) + 14), 8) = int($rg);
			vec($gif, (($cc * 3) + 15), 8) = int($rb);

			$cc++;
		}
	}

	$self->{ output_data } = $gif;
    return;
}


#==============================================================================
#
# _gif_colorise()
#
#==============================================================================

sub _gif_colorise {
	my $self = shift;

	print STDERR "$MOD: _gif_colorise called\n" if $DEBUG;

	# get the internal colors
	my $colors = $self->{ colors } || return;

	print STDERR "$MOD: _gif_colorise colors found\n" if $DEBUG;

	# get the data for the gif file
	my $gif = $self->{ data };

	# color count
	my $cc = 0;

	# there is a packed field at position 10 in the file that tells us both 
	# if there is a global color table and the size of it
	my $pf = vec($gif, 10, 8);

	# Packed field format
	#
	# 10000000 Global Color Table
	# 01110000 Color Resolution
	# 00001000 Sorted
	# 00000111 Size of Global Color Table

	# check that the gif has a global color map for us to change
	if ($pf & 128) {
		# has a color table

		# the color table can be found in the lower 3 bits of the packed field
		my $cts = $pf & 7;

		# the actual number of colors is the cts number + 1 to the 
		# power of two
		$cts = 2 ** ($cts + 1);

		print STDERR "$MOD: Color Table Size is [$cts]\n" if $DEBUG;

		# get each color from the color_string  and write it into the global 
		# color table until we have no more colors or we have run out of space
		while ($cc <= $#$colors) {
			my $c1 = @$colors[$cc];
			print STDERR "$MOD: Color replacement for [$1] [$cc]\n" if $DEBUG;

			my ($r, $g, $b) = make_rgb($c1);
			vec($gif, (($cc * 3) + 13),8) = $r;
			vec($gif, (($cc * 3) + 14),8) = $g;
			vec($gif, (($cc * 3) + 15),8) = $b;
			$cc++;
			last unless $cc < $cts;
		}
	}

	$self->{ output_data } = $gif;

	return;
}


#==============================================================================
#
# _valid_type
#
# Checks the data loaded to ensure that if is of a type that we can process
#
#==============================================================================

sub _valid_type {
	my $self = shift;

	if (lc(substr($self->{ data }, 0, 3)) eq 'gif') {
		$self->{ type } = 'gif';
	} else {
		$self->{ type } = '';
	}
}


#==============================================================================
#
# make_rgb( color )
#
# takes an rgb triple with or without the # at the start and returns a list
# of values for the red, green and blue parts
#
#==============================================================================

sub make_rgb {
	my $rgb = shift || return;
	print STDERR "$MOD: RGB is [$rgb]\n" if $DEBUG;
	$rgb =~ /^[\#_]?(..)(..)(..)$/;
	print STDERR "$MOD: Make_rgb [$1] [$2] [$3]\n" if $DEBUG;
	return map { hex($_) } ($1, $2, $3);
}


#==============================================================================
#
# _safe_dump
#
# returns a copy of the object without the binray data in it
#
#==============================================================================

sub _safe_dump {
	my $self = shift;
	my $safe;

	foreach (keys %$self) {
		next if /^data$/ || /^output_data$/;
		$safe->{ $_ } = $self->{ $_ };
	}

	$safe->{ data } = "Some gif file data" if $self->{ data };

	return $safe;
}


sub version {
	return $VERSION;
}

1;

=head1 NAME

Image::BioChrome - Colorise gif files by rewriting the color table

This module is still considered ALPHA code, the module and interfaces are
still subject to change.

=head1 SYNOPSIS

	my $bio = new Image::BioChrome $file;

	$bio->colors(.....);

	or 

	$bio->alphas(.....);

	or

	$bio->percents(100, 100, 50)

	$bio->write_file($file);

	# cause the file to be re-read from the source
	$bio->read_file();

=head1 DESCRIPTION

This module is designed to recolor images files.  I built it because I am regularly producing web sites with many common interface graphics where we just need to change the colors.  The name BioChrome comes from the name of the special color changing cells that give a Chameleon its color changing ability.

Also included in the distribution are modules that allow Apache (with mod_perl) to build images on the fly and a Template::Toolkit plugin to allow the creation of images from within a Template.

An instance of a Image::BioChrome should be created for each image file that you want to work on.

my $b = new Image::BioChrome 'test.gif';

In order to then change the colors you need to call one of the color change methods detailed below.  There the method requires a color string it will accept the input as either a string of color values or as an array ref to a set of colors.

A color string is simply a series of hexadecimal rgb triples separated by character other than 0-9, a-f or #. For example ff0000_00ff00_0000ff is red followed by green followed by blue.

$b->colors('ff0000_00ff00_0000ff')

or

$b->colors(['ff0000','00ff00','0000ff']);

or 

$b->colors('ff0000','00ff00','0000ff');

Now you may be asking yourself what the module does with the color information.  The best answer is to look at the documentation in the examples directory.  Explaining how colors are processed in ascii art is really difficult.

Once you have passed the relevant color information the file can be written to disk by calling the write file method.

$b->write_file('output.gif');

Currently BioChrome will only recolor GIF files.  Any file which it is not capable of being recolored will simply be copied when write_file is called.

=head1 Color Change Methods

=head2 alphas

Expects a color string with upto four colors.  Every color in the color palette will be changed.  The four colors are blended according to the amount of red, green and blue in the image. 

=head2 colors

Expects a set of colors upto the number of colors in the color palette.  The colors will be replaced with the colors given.

=head2 percents ( red_percent, green_percent, blue_percent )

Changes every color in the palette by adjusting the amount each part of the color by the percentages given.

=head1 SEE ALSO

L<Apache::BioChrome|Apache::BioChrome>, L<Template::Plugin::BioChrome|Template::Plugin::BioChrome>

=head1 AUTHOR

Simon Matthews E<lt>sam@tt2.comE<gt>

=head1 REVISION

$Revision: 1.16 $

=head1 COPYRIGHT 

Copyright (C) 2003 Simon Matthews.  All Rights Reserved.

This module is free software; you can distribute it and/or modify 
it under the same terms as Perl itself.

=cut
