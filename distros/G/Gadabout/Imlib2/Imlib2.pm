package Gadabout::Imlib2;

use strict;
use POSIX;
use Image::Imlib2;
use Gadabout;
use Data::Dumper;

use vars qw(@ISA $VERSION);

@ISA = qw(Gadabout);
$VERSION = '1.0001';

sub new{
    my $self = shift;
    my $class = ref($self) || $self;
    $self = $class->SUPER::new;
    bless $self, $class;
    $self;
}


sub InitImage{
  my $self = shift;
  $self->{im}   = Image::Imlib2->new($self->{image_width}, $self->{image_height});
  $self->AddFontPath('.');
  $self->SetFont("arial/8");
  $self->{im}->set_colour(255, 255, 255, 255);
  $self->{im}->fill_rectangle(0,0,$self->{image_width},$self->{image_height});
} #sub InitImage

sub SetFont{
  my $self = shift;
  $self->{font} = $self->GetImageFont(shift);
}

sub AddFontPath {
  my $self = shift;
  for (@_) {
    $self->{im}->add_font_path($_);
  }
}
sub GetImageFont{
  my $self = shift;
  my $font = shift;
  return $self->{im}->load_font($font);
} # sub GetImageFont 


sub DrawLine{
  my $self = shift;
  my $x1 = shift;
  my $y1 = shift;
  my $x2 = shift;
  my $y2 = shift;
  my $color = shift;
  $color = $self->{color}{$color};

  if (defined($color->{"red"})){
    $self->{im}->set_colour($color->{"red"}, $color->{"green"}, $color->{"blue"}, $color->{"alpha"});
    $self->{im}->draw_line($x1, $y1, $x2, $y2);
    return 1;
  } else {
    return 0;
  }
}  # sub DrawLine

sub DrawDashedLine{
  my $self = shift;
  my $x1 = shift;
  my $y1 = shift;
  my $x2 = shift;
  my $y2 = shift;
  my $dash_length = shift;
  my $dash_space = shift;
  my $color = shift;
  $color = $self->{color}{$color};

  my $line_length = $self->max(ceil (sqrt((($x2 - $x1)**2) + (($y2 - $y1)**2)) ),2);

  my $cosTheta = ($x2 - $x1) / $line_length;
  my $sinTheta = ($y2 - $y1) / $line_length;
  my $lastx    = $x1;
  my $lasty    = $y1;

  for (my $i = 0; $i < $line_length; $i += ($dash_length + $dash_space)) {
    my $x = ($dash_length * $cosTheta) + $lastx;
    my $y = ($dash_length * $sinTheta) + $lasty;
			
    $self->{im}->set_colour($color->{"red"}, $color->{"green"}, $color->{"blue"}, $color->{"alpha"});
    $self->{im}->draw_line($lastx,$lasty,$x,$y);
    $lastx = $x + ($dash_space * $cosTheta);
    $lasty = $y + ($dash_space * $sinTheta);
  }
} #sub DrawDashedLine



sub GetTextSize{
  my $self = shift;
  my $string = shift;
  my $direction = shift;
  my $font = shift;

  if (!defined($font)) {
    $font = $self->{font};
  }
  my ($width, $height) = $self->{im}->get_text_size($string, $direction);

  return {"width"  => $width, "height" => $height};
} # sub GetTextSize


sub DrawText{
  my $self = shift;
  my $font = shift;
  my $x = shift;
  my $y = shift;
  my $text = shift;
  my $color = shift;
  my $direction = shift;
  $color = $self->{color}{$color};

  $self->{im}->set_colour($color->{"red"}, $color->{"green"}, $color->{"blue"}, $color->{"alpha"});
  $self->{im}->draw_text($x,$y,$text,$direction);
} # sub DrawText


sub DrawPolygon{
  my $self = shift;
  my $vertices = shift;
  my $color = shift;
  my $closed = shift;
  if (!defined($closed)){
    $closed = 1;
  }
  $color = $self->{color}{$color};

  if (scalar(@$vertices) > 2) {
    my $poly = new Image::Imlib2::Polygon();
    for(my $i = 0; $i < scalar(@$vertices);  $i++){
      my $coords = $vertices->[$i];
      $poly->add_point($coords->{"x"},$coords->{"y"});
    }
    $self->{im}->set_colour($color->{"red"}, $color->{"green"}, $color->{"blue"}, $color->{"alpha"});
    $self->{im}->draw_polygon($poly,$closed);

    undef $poly;
  }
}


sub DrawFilledPolygon{
  my $self = shift;
  my $vertices = shift;
  my $color = shift;
  $color = $self->{color}{$color};
  my $poly  = new Image::Imlib2::Polygon();

  if (scalar(@$vertices) > 2) {
    my $poly = new Image::Imlib2::Polygon();
    for(my $i = 0; $i < scalar(@$vertices);  $i++){
      my $coords = $vertices->[$i];
      $poly->add_point($coords->{"x"},$coords->{"y"});
    }

    $self->{im}->set_colour($color->{"red"}, $color->{"green"}, $color->{"blue"}, $color->{"alpha"});
    $poly->fill();
    undef $poly;
  }
} # sub DrawFilledPolygon


sub DrawRectangle{
  my $self = shift;
  my $x = shift;
  my $y = shift;
  my $width = shift;
  my $height = shift;
  my $color = shift;
  $color = $self->{color}{$color};

  $self->{im}->set_colour($color->{"red"}, $color->{"green"}, $color->{"blue"}, $color->{"alpha"});
  $self->{im}->draw_rectangle($x,$y,$width,$height);
} #sub DrawRectangle

sub DrawGradientRectangle{
  my $self = shift;
  my $x = shift;
  my $y = shift;
  my $width = shift;
  my $height = shift;
  my $color = shift;

  my $cr = Image::Imlib2::ColorRange->new();

  my $r = $self->{color}{$color}{"red"};
  my $g = $self->{color}{$color}{"green"};
  my $b = $self->{color}{$color}{"blue"};
  my $a = $self->{color}{$color}{"alpha"};

  $x      = int($x+.5);
  $y      = int($y+.5);
  $width  = int($width+.5);
  $height = int($height+.5);

  if ($height == 1) {
    $height++;
  }

  my $colorWidth = floor($width / 2);
  my $cr = Image::Imlib2::ColorRange->new();

  $cr->add_color(-$colorWidth,$r,$g,$b,$a);
  $cr->add_color(0,255,255,255,$a);
  $cr->add_color($colorWidth,$r,$g,$b,$a);

  $self->{im}->fill_color_range_rectangle($cr,$x,$y,$width,$height,90);
  undef $cr;

} #sub DrawGradientRectangle

sub DrawEllipse{
  my $self = shift;
}

sub DrawBrush{
  my $self = shift;
  my $x = shift; 
  my $y = shift;
  my $shape = shift;
  my $color = shift;

  $color   = $self->{color}{$color};
  my @vert;
  my $numvert = 0;

  if ($shape eq "triangle"){
    my $poly = Image::Imlib2::Polygon->new();
    $poly->add_point($x + 2, $y + 2);
    $poly->add_point($x,     $y - 2);
    $poly->add_point($x - 2, $y + 2);

    $self->{im}->set_colour($color->{"red"}, $color->{"green"}, $color->{"blue"}, $color->{"alpha"});
    $poly->fill();
    undef $poly;
  }
  else{
    if ($shape eq "circle"){
      $self->{im}->set_colour($color->{"red"}, $color->{"green"}, $color->{"blue"}, $color->{"alpha"});
      $self->{im}->draw_ellipse($x,$y,2,2);
    }
    else{
      $self->{im}->set_colour($color->{"red"}, $color->{"green"}, $color->{"blue"}, $color->{"alpha"});
      $self->{im}->fill_rectangle($x-2,$y-2,5,5);
    }
  }
}#sub DrawBrush

sub DrawFilledRectangle{
  my $self = shift;
  my $x = shift;
  my $y = shift; 
  my $width = shift;
  my $height = shift;
  my $color = shift;

  $color = $self->{color}{$color};
  $self->{im}->set_colour($color->{"red"}, $color->{"green"}, $color->{"blue"}, $color->{"alpha"});
  $self->{im}->fill_rectangle($x,$y,$width,$height);		
} #sub DrawFilledRectangle

sub InitPieChart{
  my $self = shift;
  my %pieProps;
  $pieProps{"xAngle"}         = 30;
  $pieProps{"yAngle"}         = -20;
  $pieProps{"zAngle"}         = 20;

  $pieProps{"dMod"}           = 2;  # How many pixels height per polygon (one pixel for polygon, x for spacing)?
  $pieProps{"radMod"}         = 0;  # Default distance from center of the circle.  Keep this under 200
  $pieProps{"startHeightMod"} = 4;  # Do we want the pie stair stepping upward?
  $pieProps{"edgeColor"}      = "black";

  $pieProps{"maxDepth"}  = -10;

  return \%pieProps;
}#sub InitPieChart


sub ShowGraph{
  my $self = shift;
  my $filename = shift;
  $self->showDebug();
  $self->{im}->save($filename);
  undef $self->{im};
} # sub Finalize

1;

__END__

=pod

=head1 NAME

Gadabout::Imlib2

=head1 SYNOPSIS

This is an implementation of the Gadabout API based on the Imlib2 library
utilizing the Image::Imlib2 perl wrapper for that library.

=head1 COPYRIGHT

OmniTI Computer Consulting, Inc.  Copyright (c) 2003

=head1 AUTHOR

Ben Martin <bmartin@omniti.com>

OmniTI Computer Consulting, Inc.

=cut


