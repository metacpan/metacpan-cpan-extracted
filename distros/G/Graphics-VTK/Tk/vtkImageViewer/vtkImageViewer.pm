# This file converted to perltk using the tcl2perl script and much hand-editing.
#   jc 12/23/01
#


package Graphics::VTK::Tk::vtkImageViewer;

use Tk qw( Ev );

use Graphics::VTK;
use Graphics::VTK::Tk;

use AutoLoader;
use Carp;
use strict;

use base qw(Tk::Widget);

Construct Tk::Widget 'vtkImageViewer';  

bootstrap Graphics::VTK::Tk::vtkImageViewer;

sub Tk_cmd { \&Tk::vtkimageviewer };

	
sub Tk::Widget::ScrlvtkImageViewer { shift->Scrolled('vtkImageViewer' => @_) }

Tk::Methods("render", "Render", "cget", "configure", "GetImageViewer");

#
#
# Remove from hash %$args any configure-like
# options which only apply at create time (e.g. -iv )
sub CreateArgs
{
  my ($package,$parent,$args) = @_;

  # Call inherited CreateArgs First:
  my @args = $package->SUPER::CreateArgs($parent,$args);
  
  if( defined( $args->{-iv} )){ # -iv defined in args, make sure args array includes it
  	my $value = delete $args->{-iv};
	push @args, '-iv', $value;
  }  
  return @args;
}

#
sub ClassInit
{
 my ($class,$widget) = @_;
 #
 # bindings
 # window level
 $widget->bind($class,'<ButtonPress-1>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->StartWindowLevelInteraction($Ev->x,$Ev->y);
   }
 );
 $widget->bind($class,'<B1-Motion>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->UpdateWindowLevelInteraction($Ev->x,$Ev->y);
   }
 );
 $widget->bind($class,'<ButtonRelease-1>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->EndWindowLevelInteraction();
   }
 );
 #
 # Get the value
 $widget->bind($class,'<ButtonPress-3>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
   $w->StartQueryInteraction($Ev->x,$Ev->y);
   }
 );
 $widget->bind($class,'<B3-Motion>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->UpdateQueryInteraction($Ev->x,$Ev->y);
   }
 );
 $widget->bind($class,'<ButtonRelease-3>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->EndQueryInteraction();
   }
 );
 #
 $widget->bind($class,'<Expose>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->ExposeTkImageViewer($Ev->x,$Ev->y,$Ev->w,$Ev->h);
   }
 );
 $widget->bind($class,'<Enter>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->EnterTkViewer();
   }
 );
 $widget->bind($class,'<Leave>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->LeaveTkViewer();
   }
 );
 $widget->bind($class,'<KeyPress-e>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->destroy;
   }
 );
 $widget->bind($class,'<KeyPress-u>',
  sub
   {
    my $w = shift;
    # To-Do: Figure out how to make vtkInt a proper widget
    # $MW->{'.vtkInteract'}->MainWindow->deiconify;
   }
 );
 $widget->bind($class,'<KeyPress-r>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->ResetTkImageViewer();
   }
 );

}

############################################################3

sub InitObject {
 my ($widget, $args) = @_;

 my $actor;
 my $imager;
 my $mapper;
 # to avoid queing up multple expose events.
 $widget->{'Rendering'} = 0;
 #
 $imager = $widget->GetImageViewer->GetRenderer;
 #
 # stuff for window level text.
 $mapper = $widget->{'Mapper1'} = Graphics::VTK::TextMapper->new;
 $mapper->SetInput("none");
 $mapper->SetFontFamilyToTimes;
 $mapper->SetFontSize(18);
 $mapper->BoldOn;
 $mapper->ShadowOn;
 $actor = $widget->{'Actor1'} = Graphics::VTK::Actor2D->new;
 $actor->SetMapper($mapper);
 $actor->SetLayerNumber(1);
 $actor->GetPositionCoordinate->SetValue(4,22);
 $actor->GetProperty->SetColor(1,1,0.5);
 $actor->SetVisibility(0);
 $imager->AddActor2D($actor);
 #
 # stuff for window level text.
 $mapper = $widget->{'Mapper2'} = Graphics::VTK::TextMapper->new;
 $mapper->SetInput("none");
 $mapper->SetFontFamilyToTimes;
 $mapper->SetFontSize(18);
 $mapper->BoldOn;
 $mapper->ShadowOn;
 $actor = $widget->{'Actor2'} = Graphics::VTK::Actor2D->new;
 $actor->SetMapper($mapper);
 $actor->SetLayerNumber(1);
 $actor->GetPositionCoordinate->SetValue(4,4);
 $actor->GetProperty->SetColor(1,1,0.5);
 $actor->SetVisibility(0);
 $imager->AddActor2D($actor);



};


#
#
sub EnterTkViewer
{
 my $widget = shift;
 $widget->{oldFocus} = $widget->focusCurrent;
 $widget->focus;
}
#
#
sub LeaveTkViewer
{
 my $widget = shift;
 my $old;
 $old = $widget->{'OldFocus'};
 $old->focus if( $old);
}
#
#
sub ExposeTkImageViewer
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $w = shift;
 my $h = shift;
 # Do not render if we are already rendering
 if ($widget->{'Rendering'} == 1)
  {
   #puts "Abort Expose: x = $x,  y = $y"
   return;
  }
 #
 # empty the que of any other expose events
 $widget->{'Rendering'} = 1;
 $widget->update;
 $widget->{'Rendering'} = 0;
 #
 # ignore the region to redraw for now.
 #puts "Expose: x = $x,  y = $y"
 $widget->Render;
}
#
#
sub StartWindowLevelInteraction
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $actor;
 my $viewer;
 $viewer = $widget->GetImageViewer;
 #
 # save the starting mouse position and the corresponding window/level
 $widget->{'X'} = $x;
 $widget->{'Y'} = $y;
 $widget->{'Window'} = $viewer->GetColorWindow;
 $widget->{'Level'} = $viewer->GetColorLevel;
 #
 #puts "------------------------------------"
 #puts "start: ($x, $y), w = [$viewer GetColorWindow], l =[$viewer GetColorLevel] "
 #
 # make the window level text visible
 $actor = $widget->{'Actor1'};
 $actor->SetVisibility(1);
 $actor = $widget->{'Actor2'};
 $actor->SetVisibility(1);
 #
 $widget->UpdateWindowLevelInteraction($x,$y);
}
#
#
#
sub EndWindowLevelInteraction
{
 my $widget = shift;
 my $actor;
 $actor = $widget->{'Actor1'};
 $actor->SetVisibility(0);
 $actor = $widget->{'Actor2'};
 $actor->SetVisibility(0);
 $widget->Render;
}
#
#
# clicking on the window sets up sliders with current value at mouse,
# and scaled so that the whole window represents x4 change.
#
sub UpdateWindowLevelInteraction
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $dx;
 my $dy;
 my $height;
 my $level;
 my $mapper;
 my $new_level;
 my $new_window;
 my $start_x;
 my $start_y;
 my $viewer;
 my $width;
 my $window;
 $viewer = $widget->GetImageViewer;
 #
 # get the widgets dimensions
 $width = $widget->cget('-width');;
 $height = $widget->cget('-height');
 #
 # get the old window level values
 $window = $widget->{'Window'};
 $level = $widget->{'Level'};
 #
 # get starting x, y and window/level values to compute delta
 $start_x = $widget->{'X'};
 $start_y = $widget->{'Y'};
 #
 # compute normalized delta
 $dx = 4.0 * ($x - $start_x) / $width;
 $dy = 4.0 * ($start_y - $y) / $height;
 #
 # scale by current values 
 $dx = $dx * $window;
 $dy = $dy * $window;
 #
 #puts "   update: ($x, $y), dx = $dx, dy = $dy"
 #
 # abs so that direction does not flip
 if ($window < 0.0)
  {
   $dx = -$dx;
   $dy = -$dy;
  }
 #
 # compute new window level
 $new_window = $dx + $window;
 if ($new_window < 0.0)
  {
   $new_level = $dy + $level;
  }
 else
  {
   $new_level = $level - $dy;
  }
 #
 # zero window or level can trap the value.
 # put a limit of 1 / 100 value
 #
 #
 # if window is negative, then delta level should flip (down is dark).
 $dy = -$dy if ($new_window < 0.0);
 #
 #
 $viewer->SetColorWindow($new_window);
 $viewer->SetColorLevel($new_level);
 #
 $mapper = $widget->{'Mapper1'};
 $mapper->SetInput("Window: $new_window");
 #
 $mapper = $widget->{'Mapper2'};
 $mapper->SetInput("Level: $new_level");
 #
 $widget->Render;
}
#
# ----------- Reset: Set window level to show all values ---------------
#
#
sub ResetTkImageViewer
{
 my $widget = shift;
 my $high;
 my $input;
 my $low;
 my @range;
 my $viewer;
 my @whole;
 my $z;
 $viewer = $widget->GetImageViewer;
 $input = $viewer->GetInput;
 return unless ($input);
 # Get the extent in viewer
 $z = $viewer->GetZSlice;
 # x, y????
 $input->UpdateInformation;
 @whole = $input->GetWholeExtent;
 $input->SetUpdateExtent($whole[0],$whole[1],$whole[2],$whole[3],$z,$z);
 $input->Update;
 #
 @range = $input->GetScalarRange;
 $low = $range[0];
 $high = $range[1];
 #
 $viewer->SetColorWindow($high - $low);
 $viewer->SetColorLevel(($high + $low) * 0.5);
 #
 $widget->Render;
}
#
#
#
#
# ----------- Query PixleValue stuff ---------------
#
#
sub StartQueryInteraction
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $UpdateQueryInteraction;
 my $actor;
 $actor = $widget->{'Actor2'};
 $actor->SetVisibility(1);
 #
 $widget->UpdateQueryInteraction($x,$y);
}
#
#
#
sub EndQueryInteraction
{
 my $widget = shift;
 my $actor;
 $actor = $widget->{'Actor2'};
 $actor->SetVisibility(0);
 $widget->Render;
}
#
#
#
sub UpdateQueryInteraction
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $data;
 my $height;
 my $idx;
 my $input;
 my $mapper;
 my $numComps;
 my $return;
 my $str;
 my $val;
 my $viewer;
 my $xMax;
 my $xMin;
 my $yMax;
 my $yMin;
 my $z;
 my $zMax;
 my $zMin;
 $viewer = $widget->GetImageViewer;
 $input = $viewer->GetInput;
 $z = $viewer->GetZSlice;
 #
 # y is flipped upside down
 $height = $widget->cget('-height');
 $y = $height - $y;
 #
 # make sure point is in the whole extent of the image.
 ($xMin,$xMax,$yMin,$yMax,$zMin,$zMax) = $input->GetWholeExtent;
 return if ($x < $xMin || $x > $xMax || $y < $yMin || $y > $yMax || $z < $zMin || $z > $zMax);
 #
 $input->SetUpdateExtent($x,$x,$y,$y,$z,$z);
 $input->Update;
 $data = $input;
 $numComps = $data->GetNumberOfScalarComponents;
 $str = "";
 for ($idx = 0; $idx < $numComps; $idx += 1)
  {
   $val = $data->GetScalarComponentAsFloat($x,$y,$z,$idx);
   $str = sprintf("%s  %.1f",$str,$val);
  }
 #
 $mapper = $widget->{'Mapper2'};
 $mapper->SetInput("($x, $y): $str");
 #
 $widget->Render;
}
#

1;
__END__
