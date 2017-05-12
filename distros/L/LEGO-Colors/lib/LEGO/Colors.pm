package LEGO::Colors;

require 5;
use strict;
use warnings;

use LEGO::Color;

our $VERSION = "0.4";

## Class data

# Mapping of normalized names to LEGO::Color objects
my %colors;
# Mapping of normalized system names to mappings of
# normalized system-specific names to default names
# Example:
# $systems{peeron}{dkgray} = 'Dark Gray';
my %systems;

# Mapping of normalized default color names to "pretty" color names
my %pretty_color_names;
# Mapping of normalized system names to "pretty" system names
my %pretty_system_names;
# Mapping of normalized system names to mappings of "pretty"
# default names to "pretty" system-specific names
# Example:
# $pretty_system_color_names{peeron}{'Dark Gray'} = "DkGray";
my %pretty_system_color_names;

## Class methods

# Just a list of "pretty" system names.
sub get_all_system_names {
	_gen_system_hash();
	return map { $pretty_system_names{$_} } sort keys %systems;
}

# Returns a hash mapping "pretty" default names to their system-specific
# names, or back to themselves if no system-specific names are available.
sub get_color_names_for_system {
	my $class = shift;
	_gen_system_hash();
	my %args = @_;
	my $system = 'default';
	if ($args{'system'}) {
		$system = _normalize($args{'system'});
	}
	# This just maps all the names to themselves.
	if ($system eq 'default') {
		return map { $_ => $_ } values %pretty_color_names;
	}
	# Barf out if we don't recognize the system name
	unless ($pretty_system_color_names{$system}) {
		return undef;
	}
	return map {
		# Either map the default name to the system-specific name or to itself
		$_ => ($pretty_system_color_names{$system}{$_} || $_)
	} values %pretty_color_names;
}

# returns either a LEGO::Color object, or undef if something bad happens
sub get_color {
	my $class = shift;
	_gen_color_hash();
	my $system = 'default';
	my $name;
	# This is the simple case
	if (@_ == 1) {
		$name = $_[0];
	}
	else {
		# We assume they're passing in named arguments
		my %args = @_;
		$name = $args{'name'};
		if (exists $args{'system'}) {
			$system = _normalize($args{'system'});
		}
	}
	if ($system ne 'default') {
		# Remap the name
		_gen_system_hash();
		unless ($systems{$system}) {
			return undef;
		}
		$name = ($systems{$system}{_normalize($name)} || $name);
	}
	# Fetch the color
	return $colors{_normalize($name)};
}

## Private methods

# Here we're actually reading the color data out of the perldoc -- that's why
# the code section ends with DATA instead of END.  The information is fairly
# plainly laid out, so this should be pretty straightforward.
sub _gen_color_hash() {
	return if %colors;
	%colors = ();
	my $data;
	{
		local $/;
		$data = <DATA>;
	}
	# Reset it for later use
	seek(DATA, 0, 0);
	# Get rid of everything but the actual data
	if ($data =~ /Color Name\s{2,}RGB[^-]*-{70}.(.*?)-{70}/s) {
		$data = $1;
	}
	else {
		die(
			"Unable to read any color information from the perldoc!  " .
			"Something is very wrong."
		);
	}
	# Parse each line out of the data
	while ($data =~ / ([a-z ]+?)\s{2,}(\d{3}) (\d{3}) (\d{3}).*\n/gi) {
		my $norm_name = _normalize($1);
		$colors{$norm_name} = LEGO::Color->new(
			name  => $1,
			red   => $2,
			green => $3,
			blue  => $4,
		);
		# Set up the pretty name map
		$pretty_color_names{$norm_name} = $1;
	}
}

# Like above, this just reads the data out of the perldoc
sub _gen_system_hash() {
	return if %systems;
	# We need colors around to do this...
	_gen_color_hash();
	%systems = ();
	my $data;
	{
		local $/;
		$data = <DATA>;
	}
	# Reset it for later use
	seek(DATA, 0, 0);
	# Find each data section
	while ($data =~ /System Name: (\w+)\n[^-]*-{70}\n([^-]*)-{70}/gs) {
		my $system = $1;
		my $system_data = $2;
		my %system_map = ();
		my $norm_system = _normalize($system);
		# Set up the system map for this system
		$systems{$norm_system} = \%system_map;
		# Store its "pretty" name
		$pretty_system_names{$norm_system} = $system;
		my %pretty_map = ();
		# And set up the system specific map for "pretty" names
		$pretty_system_color_names{$norm_system} = \%pretty_map;
		while ($system_data =~ /([a-z ]+?)\s{2,}([a-z ]+)\n/gi) {
			# Store th color mapping
			$system_map{_normalize($2)} = $1;
			# And store the "pretty" name mapping
			$pretty_map{$pretty_color_names{_normalize($1)}} = $2;
		}
	}
}

# Boooring
sub _normalize {
	my $in = shift;
	my $out = lc($in);
	$out =~ s/\s//g;
	return $out;
}

1;

__DATA__

=head1 NAME

LEGO::Colors - Set of LEGO Color data

=head1 SYNOPSIS

 use LEGO::Colors;
 use strict;

 my @system_names = LEGO::Colors->get_all_system_names();

 my %color_map = LEGO::Colors->get_color_names_for_system(
	 'system' => 'Peeron',
 );

 my $green = LEGO::Colors->get_color("Green");

 my $gray = LEGO::Colors->get_color(
   color    => "Light Gray",
   'system' => "BrickLink",
 );

=head1 DESCRIPTION

This is a data storage class used to maintain a list of commonly used LEGO
colors and their associated RGB values.  See L<LEGO::Color> for more
information.

Different online sources of LEGO information use slightly different names
for LEGO colors.  I have chose a set of names to consider the "default",
and those names are used in this module as the default color names.
A color name aliasing system is available for access to names from other
sources.  Please see the SYSTEMS section of the documentation for more
information.

All color and system names are case and whitespace INsensitive.  That is,
"Dark Red", "darkred" and "dA RkrE d" are all considered the same.

=head1 METHODS

=over 4

=item get_all_system_names

Returns a list of all known color naming system names.  Takes no arguments.

=item get_color_names_for_system

Returns a hash mapping default color names to their equivalent color names
in the provided system.  Takes one named argument, "system", which is optional.
If omitted, default color names will be mapped to themselves, otherwise they
will be mapped to the color names from the specified naming system.

=item get_color

Returns a LEGO::Color object representing the color named by the input
arguments.  Can take arguments in two forms; if a single string value is
provided then it is assumed to be the color name from the default naming
system.  Otherwise, arguments can be passed as name => value pairs.  The
currently supported arguments are 'color', which is required, and 'system',
which is optional and will default to the default system if not provided.

=back

=head1 COLORS

The following colors are available, named here using the default naming
system:

 Color Name         RGB Value     Pantone       CMYK Value
 ----------------------------------------------------------------------
 Black              033 033 033   Hex Black     001 001 001 100
 Blue               000 087 166   2945C         100 045 000 014
 Brown              097 048 005   732C          000 055 100 064
 Dark Blue          000 048 092   540C          100 055 000 055
 Dark Gray          112 112 097   417C          001 000 025 065
 Dark Orange        179 084 008   471C          000 059 100 018
 Dark Pink          209 097 156   674C          009 067 000 000
 Dark Red           133 054 015   1685C         000 068 100 044
 Green              000 130 074   348C          100 000 085 024
 Light Gray         163 161 153   7539C         002 000 009 036
 Light Green        061 212 133   7479C         055 000 050 000
 Light Orange       247 163 010   137C          000 035 090 000
 Light Violet       171 176 199   536C          031 020 005 000
 Light Yellow       247 214 125   134C          000 011 045 000
 Lime Green         158 171 005   383C          020 000 100 019
 Maersk Blue        092 186 204   631C          067 000 012 002
 Medium Blue        120 150 207   659C          055 030 000 000
 Orange             242 125 000   151C          000 048 095 000
 Pearl Light Gray   135 135 133   Cool Gray 9   000 001 000 051
 Purple             110 018 115   2612C         064 100 000 014
 Red                189 056 038   180C          000 079 100 011
 Sand Blue          092 120 143   5415C         042 008 000 040
 Sand Green         112 130 112   5625C         028 000 029 048
 Sand Red           153 112 089   4715C         000 042 045 034
 Tan                214 191 145   7502C         000 008 035 010
 Teal               000 138 128   3282C         100 000 046 015
 White              232 227 217   Cool Gray 1   000 000 000 006
 Yellow             247 209 023   116C          000 016 100 000
 ----------------------------------------------------------------------

The preceeding data was harvested, with permission, from the wonderful
LEGO color page found at L<http://www.britdogmodels.com/misc/legocolors/>.
The color names above represent the default naming system to which all other
names are relative.

=head1 SYSTEMS

Each system has a name an then a list of color name mappings, from the
default name to that system's name.  Cases where the names are the same
will be omitted, so these lists will only contain areas of contention.
All color systems contain entries for all colors.

The following alternate naming systems are available:

 System Name: Peeron

 Default Name       Peeron Name
 ----------------------------------------------------------------------
 Dark Blue          NavyBlue
 Dark Gray          DkGray
 Dark Orange        DkOrange
 Dark Pink          DkPink
 Dark Red           DkRed
 Light Gray         Gray
 Light Green        LtGreen
 Light Orange       LtOrange
 Light Violet       LtViolet
 Light Yellow       LtYellow
 Lime Green         Lime
 Medium Blue        MdBlue
 Pearl Light Gray   PearlLtGray
 ----------------------------------------------------------------------

The information above represents the color names used by the amazingly
good LEGO inventory website, Peeron, at L<www.peeron.com>. The color
information was gathered from their color chart, at:
L<http://peeron.com/inv/colors>


 System Name: Bricklink

 Default Name       Bricklink Name
 ----------------------------------------------------------------------
 Lime Green         Lime
 ----------------------------------------------------------------------

The inforation above represents the color names used by the (unofficial)
LEGO marketplace website, BrickLink, at L<www.bricklink.com>. The color
information was gathered from their color chart, at:
L<http://www.bricklink.com/catalogColors.asp>

If your favorite naming system is missing, or the data provided here is
inaccurate or incomplete, please feel free to get in touch with me and I
will make any appropriate modifications to a future release of this module.
Note that it is also possible for you to make modifications to this file
in your local installation and thus provide any desired color naming system.


=head1 Future Work

=over 4

=item * Adding more colors to both default and alternate naming systems.

=back

=head1 Known Issues

=over 4

=item * None at this time.

=back

=head1 AUTHOR

Copyright 2007 Avi Finkel <F<avi@finkel.org>>

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

LEGO® is a trademark of the LEGO Group of companies which does
not sponsor, authorize or endorse this software.
The official LEGO website is at L<http://www.lego.com/>
=cut
