package Image::Flight::Suborbital;

use 5.008006;
use strict;
use warnings;
use GD;
use GD::Text::Align;
use Graphics::ColorNames qw( all_schemes hex2tuple );

# This is the location of the version number for the whole package
our $VERSION = '0.01';

# set up Graphics::ColorNames
our %ColorTable;
tie %ColorTable, 'Graphics::ColorNames', all_schemes();

# default configuration values
our %defaults = (
	"height" => 800,
	"width" => 250,
	"bg_color" => "white",
	"bg_top_gradient_color" => undef,
	"flight_path_color" => "black",
	"alt_label_color" => "black",
	"title_color" => "black",
	"altitude_value" => 120,
	"altitude_units" => "km",
);

# instantiate a new object
sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;
	$self->initialize( @_ );
	return $self;
}

# initialize a new object
sub initialize
{
	my $self = shift;
	$self->{config} = { @_ };
}

# turn colors to list of Red/Green/Blue values
sub strtorgb
{
	my $str = shift;

	if ( $str =~ /^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/i ) {
		return ( hex $1, hex $2, hex $3 );
	} elsif ( $str =~ /^([0-9]{1-3}),([0-9]{1-3}),([0-9]{1-3})/ ) {
		return ( $1, $2, $3 );
	} elsif ( exists $ColorTable{$str} ) {
		return @{$ColorTable{$str}};
	}
}

# convert altitude to km
sub convert_to_km
{
	my $val = shift;
	my $units = shift;

	if ( $units eq "km" ) {
		return $val;
	} elsif ( $units eq "mi" or $units eq "miles" ) {
		return $val * 1.609344;
	} elsif ( $units eq "ft" or $units eq "feet" ) {
		return $val / 3280.8399;
	} else {
		die "$0: unit $units unknown\n";
	}
}

# compute scale marks spacing
sub compute_marks
{
	my $apogee = shift;

	print STDERR "debug: compute_marks: apogee=$apogee\n";

	# compute magnitude of steps
	my $magnitude = log($apogee)/log(10);
	print STDERR "debug: compute_marks: magnitude=$magnitude\n";
	my $mag_int = int( $magnitude );
	my $mag_frac = $magnitude - $mag_int;
	print STDERR "debug: compute_marks: mag_int=$mag_int mag_frac=$mag_frac\n";
	# compute step factor
	my $step_factor;
	if ( $mag_frac >= 0.95 ) {
		$step_factor = 10;
	} elsif ( $mag_frac >= 0.6 ) {
		$step_factor = 5;
	} elsif ( $mag_frac >= 0.3 ) {
		$step_factor = 2;
	} else {
		$step_factor = 1;
	}
	print STDERR "debug: compute_marks: step_factor=$step_factor\n";

	# compute step size
	my $step_size = 10**($mag_int - 1 ) * $step_factor;
	print STDERR "debug: compute_marks: step_size=$step_size\n";

	return $step_size;
}

# draw image
sub image
{
	my $self = shift;

	# get configuration info
	my $height = ( exists $self->{config}{height})
		? $self->{config}{height}
		: $defaults{height};
	my $width = ( exists $self->{config}{width})
		? $self->{config}{width}
		: $defaults{width};
	my $title_text = ( exists $self->{config}{title_text})
		? $self->{config}{title_text}
		: $defaults{title_text};
	my $altitude_value = ( exists $self->{config}{altitude_value})
		? $self->{config}{altitude_value}
		: $defaults{altitude_value};
	my $altitude_units = ( exists $self->{config}{altitude_units})
		? $self->{config}{altitude_units}
		: $defaults{altitude_units};

	# set up GD drawing object
	my $image = new GD::Image( $width, $height );

	# allocate colors
	$self->{colors} = {};
	foreach my $color_var ( "bg", "bg_top_gradient", "flight_path",
		"alt_label", "title" )
	{
		my $color_str = ( exists $self->{config}{$color_var."_color"})
				? $self->{config}{$color_var."_color"}
				: $defaults{$color_var."_color"};
		if ( defined $color_str ) {
			$self->{colors}{$color_var."_color"} =
				$image->colorAllocate(
					hex2tuple( $ColorTable{$color_str}));
		}
	}

	# draw background gradient if specified
	if ( exists $self->{colors}{bg_top_gradient_color}) {
		my $i;
		$self->{gradient_color} = [];
		my ( $a_r, $a_g, $a_b ) =
			$image->rgb($self->{colors}{bg_color});
		my ( $b_r, $b_g, $b_b ) =
			$image->rgb($self->{colors}{bg_top_gradient_color});
		for ( $i=0; $i<100; $i++ ) {
			printf STDERR "debug: gradient %3d: %3d %3d %3d\n", $i,
				$a_r + ($b_r-$a_r)*($i/100),
				$a_g + ($b_g-$a_g)*($i/100),
				$a_b + ($b_b-$a_b)*($i/100);
			my $color = $image->colorAllocate(
				$a_r + ($b_r-$a_r)*($i/100),
				$a_g + ($b_g-$a_g)*($i/100),
				$a_b + ($b_b-$a_b)*($i/100));
			push @{$self->{gradient_color}}, $color;
			$image->filledRectangle (
				0, $height-($height-30)/100*($i+1)*((($i+1)/100)**4)-1,
				$width, $height-($height-30)/100*$i*(($i/100)**4),
				$color);
		}

		# fill in the remainder at the top
		$image->filledRectangle( 0, 0, $width, 30,
			$self->{colors}{bg_top_gradient_color});
	}

	# draw flight path arc
	$image->arc( $width/2, $height-1, ($width/3)*2, ($height-30)*2,
		180, 360, $self->{colors}{flight_path_color});
	
	# draw km scale along right side
	my $alt_km = convert_to_km ( $altitude_value, $altitude_units );
	my $km_scale_step_size = compute_marks( $alt_km );
	my $i;
	for ( $i=1; $i <= $alt_km / $km_scale_step_size; $i++ ) {
		$image->line( $width - 5,
			$height-(($height-30)/$alt_km*$km_scale_step_size)*$i,
			$width,
			$height-(($height-30)/$alt_km*$km_scale_step_size)*$i,
			$self->{colors}{alt_label_color});
		my $label_text = GD::Text::Align->new( $image,
			text => $km_scale_step_size*$i,
			font => gdSmallFont,
			ptsize => 12,
			valign => 'center',
			halign => 'right',
			color => $self->{colors}{alt_label_color});
		$label_text->draw( $width - 10,
			$height-(($height-30)/$alt_km*$km_scale_step_size)*$i,
			0 );
	}
	my $km_text = GD::Text::Align->new( $image,
		text => "km",
		font => gdSmallFont,
		ptsize => 14,
		valign => 'bottom',
		halign => 'right',
		color => $self->{colors}{alt_label_color});
	$km_text->draw( $width, 20, 0 );

	# draw miles scale along left side
	my $alt_mi = $alt_km / 1.609344;
	my $mi_scale_step_size = compute_marks( $alt_mi );
	for ( $i=1; $i <= $alt_mi / $mi_scale_step_size; $i++ ) {
		$image->line( 5,
			$height-(($height-30)/$alt_mi*$mi_scale_step_size)*$i,
			0,
			$height-(($height-30)/$alt_mi*$mi_scale_step_size)*$i,
			$self->{colors}{alt_label_color});
		my $label_text = GD::Text::Align->new( $image,
			text => $mi_scale_step_size*$i,
			font => gdSmallFont,
			ptsize => 12,
			valign => 'center',
			halign => 'left',
			color => $self->{colors}{alt_label_color});
		$label_text->draw( 10,
			$height-(($height-30)/$alt_mi*$mi_scale_step_size)*$i,
			0 );
	}
	my $mi_text = GD::Text::Align->new( $image,
		text => "miles",
		font => gdSmallFont,
		ptsize => 14,
		valign => 'bottom',
		halign => 'left',
		color => $self->{colors}{alt_label_color});
	$mi_text->draw( 0, 20, 0 );

	# return the image
	return $image->png;
}


1;
__END__

=head1 NAME

Image::Flight::Suborbital - draw diagram of suborbital rocket flight profile

=head1 SYNOPSIS

  use Image::Flight::Suborbital;

  # instantiate 
  $ifs = Image::Flight::Suborbital->new(
  	"height" => 800,
	"width" => 250,
	"title_text" => "120 km suborbital space flight",
	"altitude_value" => 120,
	"altitude_units" => "km",
  );

  # draw a PNG image and print it on the standard output
  print $ifs->image;

=head1 DESCRIPTION

Image::Flight::Suborbital uses Perl's GD graphics library to draw a
diagram of a suborbital space flight.

The following methods are available.

=head2 new() class method

  $obj = Image::Flight::Suborbital->new( attribute => value, ... )

This instantiates an Image::Flight::Suborbital object
and initializes its parameters.  The following parameters are recognized.
Unrecognized parameters are silently ignored - but should be avoided to
prevent conflicts with future versions of the module.

=head3 height attribute

Set the height of the image.

The default is 800.

=head3 width attribute

Set the width of the image.

The default is 250.

=head3 altitude_value attribute

Set the value of the altitude in either miles, kilometers or feet as specified
by the altitude_units attribute.

The default is 120.

=head3 altitude_units attribute

The units used by the altitude_value parameter.

This may only be one of the strings "km", "mi", "miles", "ft" or "feet".
The default is "km".

=head3 bg_color attribute

Set the image background color.

This may be any color string recognized by the Graphics::ColorNames module.
The default is "white".

=head3 bg_top_gradient_color attribute

If present, this turns the background to a grandient of colors.
The gradient starts at the bottom of the image with the bg_color attribute
and blending in 100 steps to the bg_top_gradient_color at the top of the
image.  The colors make the steepest transition toward the bottom of the
image in order to look like the transition from low-altitude sky to space.

This may be any color string recognized by the Graphics::ColorNames module.
If omitted, the bg_color is used as a solid background.
The default is not to use a gradient.

=head3 flight_path_color attribute

Set the color of the flight path arc.

This may be any color string recognized by the Graphics::ColorNames module.
The default is "black".

=head3 alt_label_color attribute

Set the color of the altitude labels.

This may be any color string recognized by the Graphics::ColorNames module.
The default is "black".

=head3 title_text attribute

This is currently unused but reserved for a future version.

=head3 title_color attribute

This is currently unused but reserved for a future version.

=head2 image() object method

This method outputs the PNG image of the suborbital rocket flight to the
standard output.

=head1 EXAMPLE

The following example will output a PNG image of the CSXT Space Shot 2004
which reached an apogee of 72 miles (116 km) on May 17, 2004.

  #!/usr/bin/perl
  use strict;
  use Image::Flight::Suborbital;

  my $ifs = Image::Flight::Suborbital->new(
        "bg_color" => "skyblue",
	"bg_top_gradient_color" => black,
        "flight_path_color" => "yellow",
        "alt_label_color" => "white",
        "altitude_value" => 116,
        "altitude_units" => "km" );
  print $ifs->image();

=head1 BACKGROUND STORY

Image::Flight::Suborbital was written by Ian Kluft for
Masten Space Systems ( http://www.masten-space.com/ )
for use in documentation of suborbital flights.
Thought the original idea was inspired for use by the
Stratofox Aerospace Tracking Team ( http://www.stratofox.org/ ),
in order to draw images for the web site about space launches which
Stratofox has participated in.

The module was "inspired" by an adjustment of the estimate of the
altitude of the CSXT Space Shot 2004, the first amateur space launch.
( http://www.civilianspace.com/ and
http://www.stratofox.org/pics/csxt-spaceshot-2004/ )
Upon inspection of the data from the flight computers, CSXT made an initial
altitude estimate of 77 miles (about 123 km or 400,000ft).
After further study, the official altitude was adjusted to a more conservative
72 miles (about 113km or 380,000ft).
But that was after Stratofox had drawn diagrams manually.
It had been a lot of work to draw the diagram and the scales in miles and
kilometers. 
An automated method was preferred before a need came up to draw more.
This module was written to solve that problem.

=head1 SEE ALSO

L<GD>, L<Graphics::ColorNames>

The amateur space launch which made this module necessary took place at
the Black Rock Desert in Nevada.  See Ian Kluft's Black Rock Page
( http://ian.kluft.com/blackrock/ ) for more information about rocketry
at the Black Rock Desert.

More information about rocketry can be found at
the Tripoli Rocketry Association ( http://www.tripoli.org/ ) or
the National Association of Rocketry ( http://www.nar.org/ ).

=head1 AUTHOR

Ian Kluft, E<lt>ikluft-cpan@thunder.sbay.orgE<gt>, http://ian.kluft.com/

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Ian Kluft

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
