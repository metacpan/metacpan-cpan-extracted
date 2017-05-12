#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

eval
 {
  $source->______examplesTcl_WidgetObject_tcl;
 }
;
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
eval
 {
  $source->_VTK_TCL('/vtkInt.tcl');
 }
;
#
sub BindTkImageViewer
{
 my $widget = shift;
 my $EndQueryInteraction;
 my $EndSliceInteraction;
 my $EndWindowLevelInteraction;
 my $EnterTkViewer;
 my $ExposeTkImageViewer;
 my $LeaveTkViewer;
 my $ResetTkImageViewer;
 my $StartQueryInteraction;
 my $StartSliceInteraction;
 my $StartWindowLevelInteraction;
 my $UpdateQueryInteraction;
 my $UpdateSliceInteraction;
 my $UpdateWindowLevelInteraction;
 my $exit;
 my $viewer;
 $viewer = $widget->GetImageViewer;
 # to avoid queing up multple expose events.
 $widget->{'Rendering'} = 0;
 $widget->{'WindowLevelString'} = sprintf("W/L: %1.0f/%1.0f",$viewer->GetColorWindow,$viewer->GetColorLevel);
 $widget->{'PixelPositionString'} = "Pos:";
 $widget->{'SliceString'} = sprintf("Slice: %1.0f",$viewer->GetZSlice);
 # bindings
 # window level, note the B1-motion event calls the "probe" or "query"
 # method as well as the standard window/level interaction
 $widget->bind('<ButtonPress-1>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    StartWindowLevelInteraction($W,$Ev->x,$Ev->y);
   }
 );
 $widget->bind('<B1-Motion>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    UpdateWindowLevelInteraction($W,$Ev->x,$Ev->y);
    UpdateQueryInteraction($W,$Ev->x,$Ev->y);
   }
 );
 $widget->bind('<ButtonRelease-1>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    EndWindowLevelInteraction($W);
   }
 );
 # Change the slice, note the B3-motion 
 $widget->bind('<ButtonPress-3>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    StartSliceInteraction($W,$Ev->x,$Ev->y);
   }
 );
 $widget->bind('<B3-Motion>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    UpdateSliceInteraction($W,$Ev->x,$Ev->y);
   }
 );
 $widget->bind('<ButtonRelease-3>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    EndSliceInteraction($W);
   }
 );
 # Handle enter, leave and motion event
 # Motion is bound to a "probe" or "query" operation
 $widget->bind('<Expose>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    ExposeTkImageViewer($W,$Ev->x,$Ev->y,$Ev->w,$Ev->h);
   }
 );
 $widget->bind('<Enter>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    EnterTkViewer($W);
    StartQueryInteraction($W,$Ev->x,$Ev->y);
   }
 );
 $widget->bind('<Leave>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    EndQueryInteraction($W);
    LeaveTkViewer($W);
   }
 );
 $widget->bind('<Motion>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    UpdateQueryInteraction($W,$Ev->x,$Ev->y);
   }
 );
 $widget->bind('<KeyPress-e>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    exit();
   }
 );
 $widget->bind('<KeyPress-u>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $MW->{'.vtkInteract'}->deiconify;
   }
 );
 $widget->bind('<KeyPress-r>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    ResetTkImageViewer($W);
   }
 );
}
#
sub EnterTkViewer
{
 my $widget = shift;
 my $focus;
 $widget->{'OldFocus'} = focus();
 $focus->_widget;
}
#
sub LeaveTkViewer
{
 my $widget = shift;
 my $focus;
 my $old;
 $old = $widget->{'OldFocus'};
 $focus->_old if ($old ne "");
}
#
sub ExposeTkImageViewer
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $w = shift;
 my $h = shift;
 my $return;
 # Do not render if we are already rendering
 if ($widget->{'Rendering'} == 1)
  {
   #puts "Abort Expose: x = $x,  y = $y"
   return;
  }
 # empty the que of any other expose events
 $widget->{'Rendering'} = 1;
 $MW->update;
 $widget->{'Rendering'} = 0;
 # ignore the region to redraw for now.
 #puts "Expose: x = $x,  y = $y"
 $widget->Render;
}
#
sub StartWindowLevelInteraction
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $UpdateWindowLevelInteraction;
 my $viewer;
 $viewer = $widget->GetImageViewer;
 # save the starting mouse position and the corresponding window/level
 $widget->{'X'} = $x;
 $widget->{'Y'} = $y;
 $widget->{'Window'} = $viewer->GetColorWindow;
 $widget->{'Level'} = $viewer->GetColorLevel;
 UpdateWindowLevelInteraction($widget,$x,$y);
}
#
sub EndWindowLevelInteraction
{
 my $widget = shift;
}
#
sub UpdateWindowLevelInteraction
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $dx;
 my $dy;
 my $height;
 my $high;
 my $input;
 my $level;
 my $low;
 my $new_level;
 my $new_window;
 my $range;
 my $return;
 my $start_x;
 my $start_y;
 my $viewer;
 my $width;
 my $window;
 $viewer = $widget->GetImageViewer;
 # get the widgets dimensions
 $width = ($widget->configure('-width'))[4];
 $height = ($widget->configure('-height'))[4];
 # get the old window level values
 $window = $widget->{'Window'};
 $level = $widget->{'Level'};
 $input = $viewer->GetInput;
 return if ($input eq "");
 # Get the extent in viewer
 $range = $input->GetScalarRange;
 $low = $range[0];
 $high = $range[1];
 # get starting x, y and window/level values to compute delta
 $start_x = $widget->{'X'};
 $start_y = $widget->{'Y'};
 # compute normalized delta
 $dx = 1.0 * ($x - $start_x) / $width;
 $dy = 1.0 * ($y - $start_y) / $height;
 # scale by dynamic range
 $dx = $dx * ($high - $low);
 $dy = $dy * ($high - $low);
 # compute new window level
 $new_window = $dx + $window;
 $new_level = $dy + $level;
 $new_window = 1 if ($new_window < 0.0);
 $viewer->SetColorWindow($new_window);
 $viewer->SetColorLevel($new_level);
 $widget->{'WindowLevelString'} = sprintf("W/L: %1.0f/%1.0f",$new_window,$new_level);
}
#
sub StartSliceInteraction
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $UpdateSliceInteraction;
 my $viewer;
 $viewer = $widget->GetImageViewer;
 # save the starting mouse position and the corresponding slice
 $widget->{'X'} = $x;
 $widget->{'Y'} = $y;
 $widget->{'Slice'} = $viewer->GetZSlice;
 UpdateSliceInteraction($widget,$x,$y);
}
#
sub EndSliceInteraction
{
 my $widget = shift;
}
#
sub UpdateSliceInteraction
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $dims;
 my $dy;
 my $height;
 my $maxSlice;
 my $minSlice;
 my $new_slice;
 my $slice;
 my $start_y;
 my $viewer;
 $viewer = $widget->GetImageViewer;
 # get the widgets dimensions
 $height = ($widget->configure('-height'))[4];
 # get the old slice value
 $slice = $widget->{'Slice'};
 # get the minimum/maximum slice
 $dims = $viewer->GetInput->GetWholeExtent;
 $minSlice = $dims[4];
 $maxSlice = $dims[5];
 # get starting y and slice value to compute delta
 $start_y = $widget->{'Y'};
 # compute normalized delta
 $dy = 1.0 * ($start_y - $y) / $height;
 # scale by current values 
 $dy = $dy * ($maxSlice - $minSlice);
 # compute new slice
 $new_slice = $dy + $slice;
 if ($new_slice < $minSlice)
  {
   $new_slice = $minSlice;
  }
 elsif ($new_slice > $maxSlice)
  {
   $new_slice = $maxSlice;
  }
 $new_slice = int($new_slice);
 $viewer->SetZSlice($new_slice);
 $widget->{'SliceString'} = sprintf("Slice: %1.0f",$new_slice);
 $widget->Render;
}
# ----------- Reset: Set window level to show all values ---------------
#
sub ResetTkImageViewer
{
 my $widget = shift;
 my $high;
 my $input;
 my $low;
 my $range;
 my $return;
 my $viewer;
 my $whole;
 my $z;
 $viewer = $widget->GetImageViewer;
 $input = $viewer->GetInput;
 return if ($input eq "");
 # Get the extent in viewer
 $z = $viewer->GetZSlice;
 # x, y????
 $input->UpdateInformation;
 $whole = $input->GetWholeExtent;
 $input->SetUpdateExtent($whole[0],$whole[1],$whole[2],$whole[3],$z,$z);
 $input->Update;
 $range = $input->GetScalarRange;
 $low = $range[0];
 $high = $range[1];
 $viewer->SetColorWindow($high - $low);
 $viewer->SetColorLevel(($high + $low) * 0.5);
 $widget->{'WindowLevelString'} = sprintf("W/L: %1.0f/%1.0f",$viewer->GetColorWindow,$viewer->GetColorLevel);
 $widget->Render;
}
# ----------- Query PixleValue stuff ---------------
#
sub StartQueryInteraction
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $UpdateQueryInteraction;
 UpdateQueryInteraction($widget,$x,$y);
}
#
sub EndQueryInteraction
{
 my $widget = shift;
}
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
 # y is flipped upside down
 $height = ($widget->configure('-height'))[4];
 $y = $height - $y;
 # make sure point is in the whole extent of the image.
 ($xMin,$xMax,$yMin,$yMax,$zMin,$zMax) = $input->GetWholeExtent;
 return if ($x < $xMin || $x > $xMax || $y < $yMin || $y > $yMax || $z < $zMin || $z > $zMax);
 $input->SetUpdateExtent($x,$x,$y,$y,$z,$z);
 $input->Update;
 $data = $input;
 $numComps = $data->GetNumberOfScalarComponents;
 $str = "";
 if ($numComps > 1)
  {
   for ($idx = 0; $idx < $numComps; $idx += 1)
    {
     $val = $data->GetScalarComponentAsFloat($x,$y,$z,$idx);
     $str = sprintf("%s  %1.0f",$str,$val);
    }
  }
 else
  {
   $val = $data->GetScalarComponentAsFloat($x,$y,$z,0);
   $str = sprintf("%1.0f",$val);
  }
 $widget->{'PixelPositionString'} = "\[$x, $y\] = $str";
 $widget->Render;
}

Tk->MainLoop;
