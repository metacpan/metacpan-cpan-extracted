package Math::Fractal::DLA;

use strict;
use warnings;
use Carp;
use Exporter;
use GD;
use FileHandle;
use vars qw($AUTOLOAD);
use Log::LogLite;

our @ISA = qw(Exporter);

our @EXPORT = qw();
our @EXPORT_OK = qw(debug addLogMessage loadFile setSize setPoints setBackground setFile setColors setBaseColor writeFile getFractal createImage getDirection exitOnError);
our %EXPORT_TAGS = ( all=>[qw(debug addLogMessage loadFile setSize setPoints setBackground setFile setColors setBaseColor writeFile getFractal createImage getDirection exitOnError)] );

our $VERSION = 0.21;

# Constructor
sub new
{
  my $param = shift;
  my $class = ref($param) || $param;
  my $self = {};

  # Set the random number generator
  srand(time() ^ ($$ + ($$ << 15)));
  
  # Set default values
  $self->{DEBUG} = 0;
  $self->{POINTS} = 500;
  $self->{COLORS} = 5;
  $self->{OUTPUT} = "PNG";
  $self->{IMG_WIDTH} = 400;
  $self->{IMG_HEIGHT} = 200;
  %{ $self->{BACKGROUND} } = (r => 255, g => 255, b => 255);
  %{ $self->{BASECOLOR} } = (r => 10, g => 100, b => 100);
  %{ $self->{VECTOR} } = (r => 50, g => 0, b => 0);
  bless($self,$class);
  return $self;
} # new

# Set the type of the fractal and load the package
# Parameter: name of package
sub setType
{
  my ($self,$type) = @_;
  no strict 'refs';
  unless ($type) { $self->exitOnError("No parameter defined"); }
  eval
  {
    require "Math/Fractal/DLA/".$type.".pm";
  };
  if ($@)
  {	$self->exitOnError("Can't locate package Math::Fractal::DLA::".$type); }
  $self->{TYPE} = $type;
} # setType

# Switch debug mode on or off
# Parameter: debug => true || false, logfile => file name
sub debug
{
  my $self = shift;
  my %param = @_;
  if ($param{debug}) 
  { 
    $self->{DEBUG} = 1;
    $self->{LOG} = new Log::LogLite($param{logfile});
    $self->{LOG}->template("<date>: <message>");
    $self->addLogMessage("STARTING NEW DLA-FRACTAL..");
  }
  else
  { 
    $self->{DEBUG} = 0;
  }
} # debug

# Add a message to the log file
# Parameter: message
sub addLogMessage
{
  my ($self,$msg) = @_;
  if ($self->{DEBUG})
  {
    $self->{LOG}->write($msg."\n",3);
  }
} # addLogMessage

# Load the image from a jpg or png image
# Parameter: filename
sub loadFile
{
  my $self = shift;
  my $filename = shift;
  if (-s $filename)
  {
    if (($filename =~ /\.jpg$/) || ($filename =~ /\.jpeg$/))
    { 
	  $self->{IMAGE} = GD::Image->newFromJpeg($filename) || $self->exitOnError("Can't open image ".$filename);
	  $self->addLogMessage("Loading JPG from $filename");
	  $self->{OUTPUT} = "JPG";
	} 
    elsif ($filename =~ /\.png$/)
    {
	  $self->{IMAGE} = GD::Image->newFromPng($filename) || $self->exitOnError("Can't open image ".$filename);
	  $self->addLogMessage("Loading PNG from $filename");
	  $self->{OUTPUT} = "PNG";
	}
    my ($width,$height) = $self->{IMAGE}->getBounds();
    $self->setSize(width => $width, height => $height);
  }	
  else
  {	$self->exitOnError($filename." doesn't exist"); }
} # loadFile

# Set the image size
# Parameter: width => xxx, height => xxx
sub setSize
{
  my $self = shift;
  my %param = @_;
  if ($self->{IMAGE}) { $self->exitOnError("Can't resize existing image"); }
  if ($param{width} !~ /^\d+$/) { $self->exitOnError("Parameter width is not a valid number"); }
  if ($param{height} !~ /^\d+$/) { $self->exitOnError("Parameter height is not a valid number"); }
  $self->{IMG_WIDTH} = $param{width};
  $self->{IMG_HEIGHT} = $param{height};
  $self->addLogMessage("Width: ".$param{width}.", Height: ".$param{height});
  foreach my $x (0..$param{width}+1)
  {
    foreach my $y (0..$param{height}+1)
    { 
      $self->{MATRIX}->[$x][$y] = 0;
    }
  }
  return 1;
} # setSize

# Set the number of points for the fractal
# Parameter: number of points
sub setPoints
{
  my $self = shift;
  my $number = shift;
  if ($number)
  {
    unless ($number =~ /^\d+$/) { $self->exitOnError($number." is not a valid number"); }
    $self->{POINTS} = $number;
    $self->addLogMessage("Set max. ".$self->{POINTS}." points");
  }
  else { $self->exitOnError("No parameter defined"); }
} # setPoints

# Get the number of points
sub getPoints
{
  my $self = shift; return $self->{POINTS};
} # getPoints

# Set the background color
# Parameter: r => xxx, g => xxx, b => xxx
sub setBackground
{
  my $self = shift;
  my %para = @_;
  foreach my $color (keys %para)
  {
	unless (($para{$color} >= 0) && ($para{$color} <= 255)) { $self->exitOnError("Parameter $color is not a valid color"); }
  }
  %{ $self->{BACKGROUND} } = %para;
  return 1;	
} # setBackground

# Set the output file
# Parameter: filename
sub setFile
{
  my ($self,$filename) = @_;
  $self->{FILE} = $filename;
  $self->addLogMessage("Filename $filename");
  if    (($filename =~ /\.jpg$/) || ($filename =~ /\.jpeg$/))
  {	$self->{OUTPUT} = "JPG"; }
  elsif ($filename =~ /\.png$/)
  { $self->{OUTPUT} = "PNG"; }
  $self->addLogMessage("Output mode: ".$self->{OUTPUT});
  return 1;
} # setFile

# Set the number of different colors
# Parameter: number
sub setColors
{
  my ($self,$colors) = @_;
  $self->{COLORS} = $colors;
  return 1;	
} # setColors

# Set the base color
# Parameter: base_r => xxx, base_g => xxx, base_b => xxx, add_r => xxx, add_g => xxx, add_b => xxx
sub setBaseColor
{
  my ($self) = shift;
  my %para = @_;
  foreach my $key (keys %para)
  {
    $key =~ /^[a-zA-Z]+_([rgb])$/;
    my $colkey = $1;

	if (($key =~ /^base/) && ($para{$key} >= 0) && ($para{$key} <= 255))
	{ $self->{BASECOLOR}->{$colkey} = $para{$key}; }
	elsif (($key =~ /^add/) && ($para{$key} >= -255) && ($para{$key} <= 255))
	{ $self->{VECTOR}->{$colkey} = $para{$key}; }
	else
	{ $self->exitOnError($key." is not a valid parameter"); }
  }
  return 1;	
} # setBaseColor

# Draws a pixel
# Parameter: x => xxx, y => yyy, color => x
sub drawPixel
{
  my $self = shift;
  my %para = @_;
  $self->{MATRIX}->[$para{x}][$para{y}] = $para{color};
} # drawPixel

# Write the fractal to the file
sub writeFile
{
  my ($self,$file) = @_;
  if ($file) { $self->{FILE} = $file; }
  if (-e $self->{FILE}) { unlink $self->{FILE}; }

  # Write to file
  my $pic = new FileHandle;
  $pic->open(">".$self->{FILE}) || $self->exitOnError("Can't open image ".$self->{FILE});
  binmode $pic || $self->exitOnError("Can't change image ".$self->{FILE}." to binary mode");
  if    ($self->{OUTPUT} eq "PNG") { print $pic $self->{IMAGE}->png; }
  elsif ($self->{OUTPUT} eq "JPG") { print $pic $self->{IMAGE}->jpeg(90); }
  $pic->close();
  return 1;
} # writeFile

# Return the fractal for output
sub getFractal
{
  my $self = shift;
  if    ($self->{OUTPUT} eq "PNG") { return $self->{IMAGE}->png; }
  elsif ($self->{OUTPUT} eq "JPG") { return $self->{IMAGE}->jpeg(90); }
} # getFractal

# Create the image with GD
sub createImage
{
  my $self = $_[0];

  unless ($self->{IMAGE})
  {
    $self->{IMAGE} = new GD::Image($self->{IMG_WIDTH},$self->{IMG_HEIGHT});
    $self->{IMAGE}->interlaced(0);
    $self->{IMAGE}->transparent(-1);
    my $bgcolor = $self->{IMAGE}->colorAllocate($self->{BACKGROUND}{r},$self->{BACKGROUND}{g},$self->{BACKGROUND}{b});
    $self->{IMAGE}->rectangle(0,0,$self->{IMG_WIDTH},$self->{IMG_HEIGHT},$bgcolor);
  }
    
  # Create the colors
  my %color = %{ $self->{BASECOLOR} };
  my @colors;
  $colors[1] = $self->{IMAGE}->colorAllocate($color{r},$color{g},$color{b});
  my %vector = %{ $self->{VECTOR} };
  for (my $i = 2; $i <= $self->{COLORS}; $i ++)
  {
    if (($color{r} + $vector{r} < 256) && ($color{r} + $vector{r} >= 0)) { $color{r} += $vector{r}; }
    if (($color{g} + $vector{g} < 256) && ($color{g} + $vector{g} >= 0)) { $color{g} += $vector{g}; } 	  
    if (($color{b} + $vector{b} < 256) && ($color{b} + $vector{b} >= 0)) { $color{b} += $vector{b}; } 	  
    $colors[$i] = $self->{IMAGE}->colorAllocate($color{r},$color{g},$color{b});
  } 

  foreach my $x (0..$self->{IMG_WIDTH})
  {
    foreach my $y (0..$self->{IMG_HEIGHT})
    {
	  my $pixel_value = $self->{MATRIX}->[$x][$y];
      if ($pixel_value > 0)
      {
	    $self->{IMAGE}->setPixel($x,$y,$colors[$pixel_value]);
      }
    }
  }  
} # createImage

# Get a random direction (0 - 3)
sub getDirection
{
  return sprintf("%.0f",rand(3));
} # getDirection

# Exit program if an error occured
# Parameter: message
sub exitOnError
{
  my $self = shift;
  my $msg = shift;
  $self->addLogMessage($msg);
  $self->debug(debug => 0);
  croak($msg);
} # exitOnError

# AUTOLOAD the missing methods
sub AUTOLOAD
{
  our $AUTOLOAD;
  my $self = shift;
  my $method = $AUTOLOAD;
  if ($method =~ /(.*)::(.*)$/) { $method = $2; }
  no strict 'refs';
  &{ "Math::Fractal::DLA::".$self->{TYPE}. "::".$method }($self,@_);
} # AUTOLOAD

sub DESTROY
{
  my $self = shift;
  if ($self->{DEBUG})
  {
	$self->addLogMessage("CLOSING LOG-FILE\n");
  }
} # DESTROY
 
1;

__END__
# Below is the documentation for Math::Fractal::DLA

=head1 NAME

Math::Fractal::DLA - Diffusion Limited Aggregation (DLA) Generator

=head1 SYNOPSIS

  use Math::Fractal::DLA;
  $fractal = new Math::Fractal::DLA;

  # Dynamic loading of the subclass Math::Fractal::DLA::TYPE
  $fractal->setType( TYPE ); 
  
  # Open the log file FILE
  $fractal->debug( debug => 1, logfile => FILE );

  # Add a message to the log file
  $fractal->addLogMessage( MESSAGE );
   
  # Global settings
  $fractal->setSize(width => 200, height => 200);
  $fractal->setPoints(5000);
  $fractal->setFile( FILENAME );
   
  # Color settings
  $fractal->setBackground(r => 255, g => 255, b => 255);
  $fractal->setColors(5);
  $fractal->setBaseColor(base_r => 10, base_g => 100, base_b => 100, add_r => 50, add_g => 0, add_b => 0);

  # Write the generated fractal to a file
  $fractal->writeFile();

  # Or return it
  $fractal->getFractal();
  
=head1 DESCRIPTION

Math::Fractal::DLA is a Diffusion Limited Aggregation (DLA) fractal generator

=head1 OVERVIEW

The Diffusion Limited Aggregation (DLA) fractal belongs to the group of stochastic fractals.

It was invented by the two physicists T.A. Witten and L.M. Sander in 1981.
The fractal is created by single particles which move randomly towards an target area. By hitting the area the particle becomes a part of it and the fractal grows.

Math::Fractal::DLA is just the framework for subclasses like Math::Fractal::DLA::Explode and doesn't implement any methods for fractal generation. To generate a fractal, you have to create a Math::Fractal::DLA object and load the subclass by calling the method setType. Otherwise you have to use an object from a subclass directly without calling the method setType. For the specific methods of the subclasses, take a look at their perldoc.

=head1 CONSTRUCTOR


=over 4


=item new


This is the constructor for Math::Fractal::DLA

No parameters are required

=back

=head1 METHODS

=over 4

=item debug ( debug => 1, logfile => FILENAME )

Activates the debug mode

The debug information will be appended to B<FILENAME>

=item addLogMessage ( MESSAGE )

Adds MESSAGE to the log file

=item loadFile ( FILENAME )

Loads an existing image in JPG- or PNG-format and uses it as background image

=item setSize ( width => WIDTH, height => HEIGHT )

Sets the size of the image

=item setPoints ( NUMBER )

Sets the number of points that will be used for the fractal

=item setFile ( FILENAME )

Sets the output file. Supported file formats are JPG and PNG

=item writeFile

Writes the fractal to the file specified by the method setFile

=item getFractal

Returns the fractal

=back

=head1 COLOR SETTINGS

All colors are specified with their RGB-values which range from 0 to 255. 

=over 4

=item setBackground ( r => RED, g => GREEN, b => BLUE )

Sets the background color for the image.

=item setColors ( NUMBER )

Sets the number of colors which will be used. 

=item setBaseColor ( base_r => RED, base_g => GREEN, base_b => BLUE, add_r => RED, add_g => GREEN, add_b => BLUE )

Starting with the base color, defined by base_r, base_g, base_b, the values of add_r, add_g and add_b will be added after each interval (number of points / colors). The values of add_r, add_g and add_b may be less than zero. 

Example:

You want to use 5 colors in your fractal with a base color of base_r => 10, base_g => 100, base_b => 100 and the add values of add_r => 50, add_g => 0, add_b => 0:

$fractal->setColors(5);
$fractal->setBaseColor(base_r => 10, base_g => 100, base_b => 100, add_r => 50, add_g => 0, add_b => 0);

As result the following colors will be used to draw the fractal:

(r,g,b): (10,100,100), (60,100,100), (110,100,100), (160,100,100), (210,100,100)


=back

=head1 AUTHOR

Wolfgang Gruber, w.gruber@urldirect.at

=head1 SEE ALSO

Lincoln D. Stein's GD module 

=head1 COPYRIGHT

Copyright (c) 2002 by Wolfgang Gruber. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=cut
