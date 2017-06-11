#
# XFig Drawing Library
#
# Copyright (c) 2017 D Scott Guthridge <scott_guthridge@rompromity.net>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the Artistic License as published by the Perl Foundation, either
# version 2.0 of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the Artistic License for more details.
# 
# You should have received a copy of the Artistic License along with this
# program.  If not, see <http://www.perlfoundation.org/artistic_license_2_0>.
#
use 5.014;
package Graphics::Fig::Color v1.0.1;
use strict;
use warnings;
use Carp;

my $RGB_TXT = "/usr/share/X11/rgb.txt";

my %DefaultColors = (
    default	=> -1,
    black	=>  0,
    blue	=>  1,
    blue1	=>  1,	# unofficial alias
    green	=>  2,
    green1	=>  2,	# unofficial alias
    cyan	=>  3,
    cyan1	=>  3,	# unofficial alias
    red		=>  4,
    red1	=>  4,	# unofficial alias
    magenta	=>  5,
    magenta1	=>  5,	# unofficial alias
    yellow	=>  6,
    white	=>  7,
    blue4	=>  8,
    blue3	=>  9,
    blue2	=> 10,
    ltblue	=> 11,
    green4	=> 12,
    green3	=> 13,
    green2	=> 14,
    cyan4	=> 15,
    cyan3	=> 16,
    cyan2	=> 17,
    red4	=> 18,
    red3	=> 19,
    red2	=> 20,
    magenta4	=> 21,
    magenta3	=> 22,
    magenta2	=> 23,
    brown4 	=> 24,
    brown3	=> 25,
    brown 	=> 25,	# unofficial alias
    brown2	=> 26,
    pink4	=> 27,
    pink3	=> 28,
    pink2	=> 29,
    pink1	=> 30,	# unofficial alias
    pink	=> 30,
    gold	=> 31,
);

#
# Graphics::Fig::Color::_validateName: validate a color name
#   $self: object
#   $name: color name
#
sub _validateName {
    my $self = shift;
    my $name = shift;

    if (!($name =~ m/^[^#\s]([^#]*[^# ])?$/)) {
	croak("${name}: error: invalid color name");
    }
    return 1;
}

#
# Graphics::Fig::Color::_validateHex validate a hexadecimal color code
#   $self: object
#   $hex:  hex code
#
sub _validateHex {
    my $self = shift;
    my $hex = shift;

    if (!($hex =~ m/^#[[:xdigit:]]{6}$/)) {
	croak("${hex}: error: invalid hex color name; #xxxxxx expected");
    }
    return 1;
}

#
# Graphics::Fig::Color::_hexToNumber: map a hex color to xfig color number
#   $self: object
#   $hex:  hex code
#
sub _hexToNumber {
    my $self = shift;
    my $hex  = shift;
    my $hexToNumber = ${$self}{"hexToNumber"};
    my $number;

    if (defined($number = $hexToNumber->{$hex})) {
	return $number;
    }

    my $customHex = ${$self}{"customHex"};
    if ($#{$customHex} == 511) {
	croak("error: too many colors");
    }
    $number = 31 + push(@{$customHex}, $hex);
    $hexToNumber->{$hex} = $number;
    return $number;
}

#
# Graphics::Fig::Color::_rgbTxtToHex
#   $self:  object
#   $color: color name
#
sub _rgbTxtToHex {
    my $self  = shift;
    my $color = shift;
    my $rgbTxtToHex;

    if (!defined($rgbTxtToHex = ${$self}{"rgbTxtToHex"})) {
	if (!open(RGB, "<", $RGB_TXT)) {
	    croak("open: ${RGB_TXT}: $!");
	    return undef;
	}
	$rgbTxtToHex = {};
	while (<RGB>) {
	    if (/^\s*(\d+)\s+(\d+)\s+(\d+)\s*([^\s](.*[^\s])?)\s*$/) {
		my $name = $4;
		my $hex  = sprintf("#%02x%02x%02x", $1, $2, $3);

		$name = lc($name);
		$rgbTxtToHex->{$name} = $hex;
	    }
	}
	close(RGB);
	${$self}{"rgbTxtToHex"} = $rgbTxtToHex;
    }
    return $rgbTxtToHex->{$color};
}

#
# Graphics::Fig::Color::new: constructor
#   $proto: prototype
#
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {
	nameToNumber	=> {},		# color name to xfig number
	hexToNumber	=> {},  	# "#xxxxxx" to xfig number
	customHex	=> [],		# table of custom hex colors
	rgbTxtToHex	=> undef,	# rgb.txt color to hex
    };
    %{${$self}{"nameToNumber"}} = %DefaultColors;

    bless($self, $class);
    return $self;
}

#
# Graphics::Fig::Color::convert map color name to xfig number
#   $self:  object
#   $color: color name or #xxxxxx hex code
#
sub convert {
    my $self  = shift;
    my $color = shift;
    my $nameToNumber = ${$self}{"nameToNumber"};
    my $temp;

    #
    # If the mapping already exists in nameToNumber, return it.
    #
    $color = lc($color);
    if (defined($temp = $nameToNumber->{$color})) {
	return $temp;
    }

    #
    # If a hex color was given, validate it.
    #
    if ($color =~ m/^#/) {
	$self->_validateHex($color);
	return $self->_hexToNumber($color);
    }

    #
    # Look for a definition in rgb.txt.
    #
    $self->_validateName($color);
    if (defined($temp = $self->_rgbTxtToHex($color))) {
	my $number = $self->_hexToNumber($temp);
	$nameToNumber->{$color} = $number;
	return $number;
    }

    croak("${color}: error: invalid color");
}

#
# Graphics::Fig::Color::define define a custom color
#   $self: object
#   $name: color name
#   $hex:  custom color in hex
#
sub define {
    my $self = shift;
    my $name = shift;
    my $hex  = shift;
    my $nameToNumber = ${$self}{"nameToNumber"};
    my $number;

    $self->_validateName($name);
    $self->_validateHex($hex);
    if (defined($number = $nameToNumber->{$name})) {
	if ($number < 32) {
	    croak("${name}: error: can't redefine built-in color");
	}
	my $customHex = ${$self}{"customHex"};
	if ($hex ne ${$customHex}[$number - 32]) {
	    carp("${name}: warning: color redefined");
	}
    }
    $number = $self->_hexToNumber($hex);
    $nameToNumber->{$name} = $number;
    return 1;
}

1;
