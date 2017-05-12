# This file converted to perltk using the tcl2perl script and much hand-editing.
#   jc 12/23/01
#


package Graphics::VTK::Tk::vtkInteractor;

use Tk qw( Ev );

use Math::Trig; # Needed for tan, etc
use Graphics::VTK;
use Graphics::VTK::Tk;

use AutoLoader;
use Carp;
use strict;
use vars( qw/   $RendererFound  $CurrentRenderWindow $TkInteractor_StartRenderMethod $TkInteractor_EndRenderMethod
	      $CurrentRenderer  $TkInteractor_StillUpdateRate $TkInteractor_InteractiveUpdateRate
	        / );


use base qw(Tk::Widget);

Construct Tk::Widget 'vtkInteractor';  

bootstrap Graphics::VTK::Tk::vtkInteractor;

sub Tk_cmd { \&Tk::vtkinteractor };

sub Tk::Widget::ScrlvtkInteractor { shift->Scrolled('vtkInteractor' => @_) }

Tk::Methods("render", "Render", "cget", "configure", "GetRenderWindow");

#
# Remove from hash %$args any configure-like
# options which only apply at create time (e.g. -rw )
sub CreateArgs
{
  my ($package,$parent,$args) = @_;

  # Call inherited CreateArgs First:
  my @args = $package->SUPER::CreateArgs($parent,$args);
  
  if( defined( $args->{-rw} )){ # -rw defined in args, make sure args array includes it
  	my $value = delete $args->{-rw};
	push @args, '-rw', $value;
  }  
  return @args;
}

#
$TkInteractor_StartRenderMethod = undef;
$TkInteractor_EndRenderMethod = undef;
$TkInteractor_InteractiveUpdateRate = 15.0;
$TkInteractor_StillUpdateRate = 0.1;
#
#
sub ClassInit
{
 my ($class,$widget) = @_;
 my $focus;
  
 
 $widget->bind($class, '<Any-ButtonPress>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->StartMotion($Ev->x,$Ev->y);
   }
 );
 $widget->bind($class, '<Any-ButtonRelease>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->EndMotion($Ev->x,$Ev->y);
   }
 );
 $widget->bind($class, '<B1-Motion>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->Rotate($Ev->x,$Ev->y);
   }
 );
 $widget->bind($class, '<B2-Motion>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->Pan($Ev->x,$Ev->y);
   }
 );
 $widget->bind($class, '<B3-Motion>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->Zoom($Ev->x,$Ev->y);
   }
 );
 $widget->bind($class, '<Shift-B1-Motion>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->Pan($Ev->x,$Ev->y);
   }
 );
 $widget->bind($class, '<Shift-B3-Motion>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->RubberZoom($Ev->x,$Ev->y);
   }
 );
 $widget->bind($class, '<KeyPress-r>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->Reset($Ev->x,$Ev->y);
   }
 );
 $widget->bind($class, '<KeyPress-u>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    # To-Do: Figure out how to make vtkInt a proper widget
    # $MW->{'.vtkInteract'}->MainWindow->deiconify;
   }
 );
 $widget->bind($class, '<KeyPress-w>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->Wireframe();
   }
 );
 $widget->bind($class, '<KeyPress-s>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->Surface();
   }
 );
 $widget->bind($class, '<KeyPress-p>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->PickActor($Ev->x,$Ev->y);
   }
 );
 $widget->bind($class, '<Enter>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->Enter($Ev->x,$Ev->y);
   }
 );
 $widget->bind($class, '<Leave>',
  sub
   {
    my $w = shift;
    $w->{oldFocus} = $w->focusCurrent;
   }
 );
 $widget->bind($class, '<Expose>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $w->Expose();
   }
 );
}


sub InitObject {
 my ($widget, $args) = @_;
 # Create member data:
 # Objects used to display rubberband
 $widget->{RubberBandPoints} = Graphics::VTK::Points->new;
 $widget->{RubberBandLines} = Graphics::VTK::CellArray->new;
 $widget->{RubberBandScalars} = Graphics::VTK::FloatArray->new;
 $widget->{RubberBandPolyData} = Graphics::VTK::PolyData->new;
 $widget->{RubberBandMapper} = Graphics::VTK::PolyDataMapper2D->new;
 $widget->{RubberBandActor} = Graphics::VTK::Actor2D->new;
 $widget->{RubberBandColors} = Graphics::VTK::LookupTable->new;
 #
 $widget->{RubberBandPolyData}->SetPoints($widget->{RubberBandPoints});
 $widget->{RubberBandPolyData}->SetLines($widget->{RubberBandLines});
 $widget->{RubberBandMapper}->SetInput($widget->{RubberBandPolyData});
 $widget->{RubberBandMapper}->SetLookupTable($widget->{RubberBandColors});
 $widget->{RubberBandActor}->SetMapper($widget->{RubberBandMapper});
 #
 $widget->{RubberBandColors}->SetNumberOfTableValues(2);
 $widget->{RubberBandColors}->SetNumberOfColors(2);
 $widget->{RubberBandColors}->SetTableValue(0,1.0,0.0,0.0,1.0);
 $widget->{RubberBandColors}->SetTableValue(1,1.0,1.0,1.0,1.0);
 #
 $widget->{RubberBandPolyData}->GetPointData->SetScalars($widget->{RubberBandScalars});
 #
 $widget->{RubberBandMapper}->SetScalarRange(0,1);
 #
 $widget->{RubberBandPoints}->InsertPoint(0,0,0,0);
 $widget->{RubberBandPoints}->InsertPoint(1,0,10,0);
 $widget->{RubberBandPoints}->InsertPoint(2,10,10,0);
 $widget->{RubberBandPoints}->InsertPoint(3,10,0,0);
 #
 $widget->{RubberBandLines}->InsertNextCell(5);
 $widget->{RubberBandLines}->InsertCellPoint(0);
 $widget->{RubberBandLines}->InsertCellPoint(1);
 $widget->{RubberBandLines}->InsertCellPoint(2);
 $widget->{RubberBandLines}->InsertCellPoint(3);
 $widget->{RubberBandLines}->InsertCellPoint(0);
 #
 $widget->{RubberBandScalars}->InsertNextValue(0);
 $widget->{RubberBandScalars}->InsertNextValue(1);
 $widget->{RubberBandScalars}->InsertNextValue(0);
 $widget->{RubberBandScalars}->InsertNextValue(1);
 #
 $widget->{RubberBandMapper}->ScalarVisibilityOn;
 
 # Used to support picking operations
 #
 $widget->{PickedAssembly} = undef;
 $widget->{ActorPicker} = Graphics::VTK::CellPicker->new;
 $widget->{PickedProperty} = Graphics::VTK::Property->new;
 $widget->{PickedProperty}->SetColor(1,0,0);
 $widget->{PrePickedProperty} = undef;

 # Flags:
 $widget->{'InExpose'} = 0;

};


#
# a litle more complex than just "bind $widget <Expose> {%W Render}"
# we have to handle all pending expose events otherwise they que up.
#
sub Expose
{
 my $widget = shift;
 # Global Variables Declared for this function: TkInteractor_StillUpdateRate
 return if ( $widget->{InExpose} && $widget->{'InExpose'} == 1);
 $widget->{'InExpose'} = 1;
 $widget->GetRenderWindow->SetDesiredUpdateRate($TkInteractor_StillUpdateRate);
 $widget->update;
 $widget->GetRenderWindow->Render;
 $widget->{'InExpose'} = 0;
}
#
# Global variable keeps track of whether active renderer was found
$RendererFound = 0;
#
# Create event bindings
#
#
sub _Render
{
 my $widget = shift;
 # Global Variables Declared for this function: CurrentCamera, CurrentLight
 # Global Variables Declared for this function: TkInteractor_StartRenderMethod
 # Global Variables Declared for this function: TkInteractor_EndRenderMethod
 #
 if( $TkInteractor_StartRenderMethod){
	&$TkInteractor_StartRenderMethod();
 }
 #
 $widget->{CurrentLight}->SetPosition($widget->{CurrentCamera}->GetPosition);
 $widget->{CurrentLight}->SetFocalPoint($widget->{CurrentCamera}->GetFocalPoint);
 #
 $widget->Render;
 #
 if( $TkInteractor_EndRenderMethod){
	&$TkInteractor_EndRenderMethod();
 }
}
#
#
sub UpdateRenderer
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $WindowX;
 my $WindowY;
 my $break;
 my $i;
 my $lights;
 my $numRenderers;
 my $renderers;
 my @viewport;
 my $vpxmax;
 my $vpxmin;
 my $vpymax;
 my $vpymin;
 my $vx;
 my $vy;
 # Global Variables Declared for this function: CurrentCamera, CurrentLight
 # Global Variables Declared for this function: CurrentRenderWindow, CurrentRenderer
 # Global Variables Declared for this function: RendererFound, LastX, LastY
 # Global Variables Declared for this function: WindowCenterX, WindowCenterY
 #
 # Get the renderer window dimensions
 $WindowX = $widget->cget('-width');
 $WindowY = $widget->cget('-height');
 #
 # Find which renderer event has occurred in
 $CurrentRenderWindow = $widget->GetRenderWindow;
 $renderers = $CurrentRenderWindow->GetRenderers;
 $numRenderers = $renderers->GetNumberOfItems;
 #
 $renderers->InitTraversal;
 $RendererFound = 0;
 for ($i = 0; $i < $numRenderers; $i += 1)
  {
   $CurrentRenderer = $renderers->GetNextItem;
   $vx = ($x) / $WindowX;
   $vy = ($WindowY - ($y)) / $WindowY;
   @viewport = $CurrentRenderer->GetViewport;
   $vpxmin = $viewport[0];
   $vpymin = $viewport[1];
   $vpxmax = $viewport[2];
   $vpymax = $viewport[3];
   if ($vx >= $vpxmin && $vx <= $vpxmax && $vy >= $vpymin && $vy <= $vpymax)
    {
     $RendererFound = 1;
     $widget->{WindowCenterX} = ($WindowX) * (($vpxmax - $vpxmin) / 2.0 + $vpxmin);
     $widget->{WindowCenterY} = ($WindowY) * (($vpymax - $vpymin) / 2.0 + $vpymin);
     last;
    }
  }
 #
 $widget->{CurrentCamera} = $CurrentRenderer->GetActiveCamera;
 $lights = $CurrentRenderer->GetLights;
 $lights->InitTraversal;
 $widget->{CurrentLight} = $lights->GetNextItem;
 #
 $widget->{LastX} = $x;
 $widget->{LastY} = $y;
}
#
#
sub Enter
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 #
 $widget->{oldFocus} = $widget->focusCurrent();
 $widget->focus;
 $widget->UpdateRenderer($x,$y);
}
#
#
sub StartMotion
{ 
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 # Global Variables Declared for this function: CurrentCamera, CurrentLight
 # Global Variables Declared for this function: CurrentRenderWindow, CurrentRenderer
 # Global Variables Declared for this function: LastX, LastY
 # Global Variables Declared for this function: RendererFound
 # Global Variables Declared for this function: TkInteractor_InteractiveUpdateRate
 # Global Variables Declared for this function: RubberZoomPerformed
 #
 $widget->UpdateRenderer($x,$y);
 return unless ($RendererFound);
 #
 $widget->{RubberZoomPerformed} = 0;
 #
 $CurrentRenderWindow->SetDesiredUpdateRate($TkInteractor_InteractiveUpdateRate);
}
#
#
sub EndMotion
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 #
 return unless ($RendererFound);
 $CurrentRenderWindow->SetDesiredUpdateRate($TkInteractor_StillUpdateRate);
 #
 #
 if ($widget->{RubberZoomPerformed})
  {
   $CurrentRenderer->RemoveProp($widget->{RubberBandActor});
   $widget->DoRubberZoom();
  }
 #
 $widget->_Render;
}
#
#
# Called when the mouse button is release - do the zoom
#
sub DoRubberZoom
{
 my $widget = shift;
 my @DPoint;
 my @FPoint;
 my $FPoint0;
 my $FPoint1;
 my $FPoint2;
 my @PPoint;
 my $PPoint0;
 my $PPoint1;
 my $PPoint2;
 my $WindowY;
 my $angle;
 my $centerX;
 my $centerY;
 my $d;
 my $factor;
 my $focalDepth;
 my @focalEdge;
 my $focalEdge0;
 my $focalEdge1;
 my $focalEdge2;
 my $focalEdge3;
 my @nearFocalPoint;
 my $nearFocalPoint0;
 my $nearFocalPoint1;
 my $nearFocalPoint2;
 my $nearFocalPoint3;
 my $nearplane;
 my @newFocalPoint;
 my $newFocalPoint0;
 my $newFocalPoint1;
 my $newFocalPoint2;
 my $newFocalPoint3;
 my @newPosition;
 my $newPosition0;
 my $newPosition1;
 my $newPosition2;
 my $newPosition3;
 my $newScale;
 my $positionDepth;
 my @range;
 my $ydiff;
 my $ydist;
 # Global Variables Declared for this function: RendererFound
 #
 # Return if there is no renderer, or the rubber band is less
 # that 5 pixels in either direction
 return unless ($RendererFound);
 return if ($widget->{StartRubberZoomX} - $widget->{EndRubberZoomX} < 5 && $widget->{StartRubberZoomX} - $widget->{EndRubberZoomX} > -5);
 return if ($widget->{StartRubberZoomY} - $widget->{EndRubberZoomY} < 5 && $widget->{StartRubberZoomY} - $widget->{EndRubberZoomY} > -5);
 #
 # We'll need the window height later
 $WindowY = $widget->cget('-height');
 #
 # What is the center of the rubber band box in pixels?
 $centerX = ($widget->{StartRubberZoomX} + $widget->{EndRubberZoomX}) / 2.0;
 $centerY = ($widget->{StartRubberZoomY} + $widget->{EndRubberZoomY}) / 2.0;
 #
 # Convert the focal point to a display coordinate in order to get the
 # depth of the focal point in display units
 @FPoint = $widget->{CurrentCamera}->GetFocalPoint;
 $FPoint0 = $FPoint[0];
 $FPoint1 = $FPoint[1];
 $FPoint2 = $FPoint[2];
 $CurrentRenderer->SetWorldPoint($FPoint0,$FPoint1,$FPoint2,1.0);
 $CurrentRenderer->WorldToDisplay;
 @DPoint = $CurrentRenderer->GetDisplayPoint;
 $focalDepth = $DPoint[2];
 #
 # Convert the position of the camera to a display coordinate in order
 # to get the depth of the camera in display coordinates. Note this is
 # a negative number (behind the near clipping plane of 0) but it works
 # ok anyway
 @PPoint = $widget->{CurrentCamera}->GetPosition;
 $PPoint0 = $PPoint[0];
 $PPoint1 = $PPoint[1];
 $PPoint2 = $PPoint[2];
 $CurrentRenderer->SetWorldPoint($PPoint0,$PPoint1,$PPoint2,1.0);
 $CurrentRenderer->WorldToDisplay;
 @DPoint = $CurrentRenderer->GetDisplayPoint;
 $positionDepth = $DPoint[2];
 #
 # Find out the world position of where our new focal point should
 # be - it will be at the center of the box, back at the same focal depth
 # Don't actually set it now - we need to do all our computations before
 # we modify the camera
 $CurrentRenderer->SetDisplayPoint($centerX,$centerY,$focalDepth);
 $CurrentRenderer->DisplayToWorld;
 @newFocalPoint = $CurrentRenderer->GetWorldPoint;
 $newFocalPoint0 = $newFocalPoint[0];
 $newFocalPoint1 = $newFocalPoint[1];
 $newFocalPoint2 = $newFocalPoint[2];
 $newFocalPoint3 = $newFocalPoint[3];
 if ($newFocalPoint3 != 0.0)
  {
   $newFocalPoint0 = $newFocalPoint0 / $newFocalPoint3;
   $newFocalPoint1 = $newFocalPoint1 / $newFocalPoint3;
   $newFocalPoint2 = $newFocalPoint2 / $newFocalPoint3;
  }
 #
 # Find out where the new camera position will be - at the center of
 # the rubber band box at the position depth. Don't set it yet...
 $CurrentRenderer->SetDisplayPoint($centerX,$centerY,$positionDepth);
 $CurrentRenderer->DisplayToWorld;
 @newPosition = $CurrentRenderer->GetWorldPoint;
 $newPosition0 = $newPosition[0];
 $newPosition1 = $newPosition[1];
 $newPosition2 = $newPosition[2];
 $newPosition3 = $newPosition[3];
 if ($newPosition3 != 0.0)
  {
   $newPosition0 = $newPosition0 / $newPosition3;
   $newPosition1 = $newPosition1 / $newPosition3;
   $newPosition2 = $newPosition2 / $newPosition3;
  }
 #
 # We figured out how to position the camera to be centered, now we
 # need to "zoom". In parallel, this is simple since we only need to
 # change our parallel scale to encompass the entire y range of the
 # rubber band box. In perspective, we assume the box is drawn on the
 # near plane - this means that it is not possible that someone can
 # draw a rubber band box around a nearby object and dolly past it. It 
 # also means that you won't get very close to distance objects - but that
 # seems better than getting lost.
 if ($widget->{CurrentCamera}->GetParallelProjection)
  {
   # the new scale is just based on the y size of the rubber band box
   # compared to the y size of the window
   $ydiff = $widget->{StartRubberZoomX} - $widget->{EndRubberZoomX};
   $ydiff = $ydiff * -1.0 if ($ydiff < 0.0);
   $newScale = $widget->{CurrentCamera}->GetParallelScale;
   $newScale = $newScale * $ydiff / $WindowY;
   #
   # now we can actually modify the camera
   $widget->{CurrentCamera}->SetFocalPoint($newFocalPoint0,$newFocalPoint1,$newFocalPoint2);
   $widget->{CurrentCamera}->SetPosition($newPosition0,$newPosition1,$newPosition2);
   $widget->{CurrentCamera}->SetParallelScale($newScale);
   #
  }
 else
  {
   # find out the center of the rubber band box on the near plane
   $CurrentRenderer->SetDisplayPoint($centerX,$centerY,0.0);
   $CurrentRenderer->DisplayToWorld;
   @nearFocalPoint = $CurrentRenderer->GetWorldPoint;
   $nearFocalPoint0 = $nearFocalPoint[0];
   $nearFocalPoint1 = $nearFocalPoint[1];
   $nearFocalPoint2 = $nearFocalPoint[2];
   $nearFocalPoint3 = $nearFocalPoint[3];
   if ($nearFocalPoint3 != 0.0)
    {
     $nearFocalPoint0 = $nearFocalPoint0 / $nearFocalPoint3;
     $nearFocalPoint1 = $nearFocalPoint1 / $nearFocalPoint3;
     $nearFocalPoint2 = $nearFocalPoint2 / $nearFocalPoint3;
    }
   #
   # find the world coordinates of the point centered on the rubber band box
   # in x, on the border in y, and at the near plane depth.
   $CurrentRenderer->SetDisplayPoint($centerX,$widget->{StartRubberZoomY},0.0);
   $CurrentRenderer->DisplayToWorld;
   @focalEdge = $CurrentRenderer->GetWorldPoint;
   $focalEdge0 = $focalEdge[0];
   $focalEdge1 = $focalEdge[1];
   $focalEdge2 = $focalEdge[2];
   $focalEdge3 = $focalEdge[3];
   if ($focalEdge3 != 0.0)
    {
     $focalEdge0 = $focalEdge0 / $focalEdge3;
     $focalEdge1 = $focalEdge1 / $focalEdge3;
     $focalEdge2 = $focalEdge2 / $focalEdge3;
    }
   #
   # how far is this "rubberband edge point" from the focal point?
   $ydist = sqrt(($nearFocalPoint0 - $focalEdge0) * ($nearFocalPoint0 - $focalEdge0) + ($nearFocalPoint1 - $focalEdge1) * ($nearFocalPoint1 - $focalEdge1) + ($nearFocalPoint2 - $focalEdge2) * ($nearFocalPoint2 - $focalEdge2));
   #
   # We need to know how far back we must be so that when we view the scene
   # with the current view angle, we see all of the y range of the rubber
   # band box. Use a simple tangent equation - opposite / adjacent = tan theta
   # where opposite is half the y height of the rubber band box on the near
   # plane, adjacent is the distance we are solving for, and theta is half
   # the viewing angle. This distance that we solve for is the new distance
   # to the near plane - to find the new distance to the focal plane we
   # must take the old distance to the focal plane, subtract the near plane
   # distance, and add in the distance we solved for.
   $angle = 0.5 * 3.141592 / 180.0 * $widget->{CurrentCamera}->GetViewAngle;
   $d = $ydist / tan($angle);
   @range = $widget->{CurrentCamera}->GetClippingRange;
   $nearplane = $range[0];
   $factor = $widget->{CurrentCamera}->GetDistance / ($widget->{CurrentCamera}->GetDistance - $nearplane + $d);
   #
   # now we can actually modify the camera
   $widget->{CurrentCamera}->SetFocalPoint($newFocalPoint0,$newFocalPoint1,$newFocalPoint2);
   $widget->{CurrentCamera}->SetPosition($newPosition0,$newPosition1,$newPosition2);
   $widget->{CurrentCamera}->Dolly($factor);
   $CurrentRenderer->ResetCameraClippingRange;
  }
}
#
#
sub Rotate
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 # Global Variables Declared for this function: RendererFound
 #
 return unless ($RendererFound);
 #
 $widget->{CurrentCamera}->Azimuth($widget->{LastX} - $x);
 $widget->{CurrentCamera}->Elevation($y - $widget->{LastY});
 $widget->{CurrentCamera}->OrthogonalizeViewUp;
 #
 $widget->{LastX} = $x;
 $widget->{LastY} = $y;
 #
 $widget->_Render();
}
#
#
sub RubberZoom
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $WindowY;
 # Global Variables Declared for this function: RendererFound
 # Global Variables Declared for this function: CurrentRenderer
 #
 return unless ($RendererFound);
 #
 $WindowY = $widget->cget('-height');
 #
 unless ($widget->{RubberZoomPerformed})
  {
   $CurrentRenderer->AddProp($widget->{RubberBandActor});
   #
   $widget->{StartRubberZoomX} = $x;
   $widget->{StartRubberZoomY} = $WindowY - $y - 1;
   #
   $widget->{RubberZoomPerformed} = 1;
  }
 #
 $widget->{EndRubberZoomX} = $x;
 $widget->{EndRubberZoomY} = $WindowY - $y - 1;
 #
 $widget->{RubberBandPoints}->SetPoint(0,$widget->{StartRubberZoomX},$widget->{StartRubberZoomY},0);
 $widget->{RubberBandPoints}->SetPoint(1,$widget->{StartRubberZoomX},$widget->{EndRubberZoomY},0);
 $widget->{RubberBandPoints}->SetPoint(2,$widget->{EndRubberZoomX},$widget->{EndRubberZoomY},0);
 $widget->{RubberBandPoints}->SetPoint(3,$widget->{EndRubberZoomX},$widget->{StartRubberZoomY},0);
 #
 $widget->_Render();
}
#
#
#
sub Pan
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $APoint0;
 my $APoint1;
 my @DPoint;
 my @FPoint;
 my $FPoint0;
 my $FPoint1;
 my $FPoint2;
 my @PPoint;
 my $PPoint0;
 my $PPoint1;
 my $PPoint2;
 my @RPoint;
 my $RPoint0;
 my $RPoint1;
 my $RPoint2;
 my $RPoint3;
 my $Render;
 my $focalDepth;
 my $return;
 # Global Variables Declared for this function: CurrentRenderer, CurrentCamera
 # Global Variables Declared for this function: RendererFound
 #
 return unless ($RendererFound);
 #
 @FPoint = $widget->{CurrentCamera}->GetFocalPoint;
 $FPoint0 = $FPoint[0];
 $FPoint1 = $FPoint[1];
 $FPoint2 = $FPoint[2];
 #
 @PPoint = $widget->{CurrentCamera}->GetPosition;
 $PPoint0 = $PPoint[0];
 $PPoint1 = $PPoint[1];
 $PPoint2 = $PPoint[2];
 #
 $CurrentRenderer->SetWorldPoint($FPoint0,$FPoint1,$FPoint2,1.0);
 $CurrentRenderer->WorldToDisplay;
 @DPoint = $CurrentRenderer->GetDisplayPoint;
 $focalDepth = $DPoint[2];
 #
 $APoint0 = $widget->{WindowCenterX} + ($x - $widget->{LastX});
 $APoint1 = $widget->{WindowCenterY} - ($y - $widget->{LastY});
 #
 $CurrentRenderer->SetDisplayPoint($APoint0,$APoint1,$focalDepth);
 $CurrentRenderer->DisplayToWorld;
 @RPoint = $CurrentRenderer->GetWorldPoint;
 $RPoint0 = $RPoint[0];
 $RPoint1 = $RPoint[1];
 $RPoint2 = $RPoint[2];
 $RPoint3 = $RPoint[3];
 if ($RPoint3 != 0.0)
  {
   $RPoint0 = $RPoint0 / $RPoint3;
   $RPoint1 = $RPoint1 / $RPoint3;
   $RPoint2 = $RPoint2 / $RPoint3;
  }
 #
 $widget->{CurrentCamera}->SetFocalPoint(($FPoint0 - $RPoint0) / 2.0 + $FPoint0,($FPoint1 - $RPoint1) / 2.0 + $FPoint1,($FPoint2 - $RPoint2) / 2.0 + $FPoint2);
 #
 $widget->{CurrentCamera}->SetPosition(($FPoint0 - $RPoint0) / 2.0 + $PPoint0,($FPoint1 - $RPoint1) / 2.0 + $PPoint1,($FPoint2 - $RPoint2) / 2.0 + $PPoint2);
 #
 $widget->{LastX} = $x;
 $widget->{LastY} = $y;
 #
 $widget->_Render;
}
#
#
sub Zoom
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $Render;
 my $parallelScale;
 my $return;
 my $zoomFactor;
 # Global Variables Declared for this function: CurrentCamera, CurrentRenderer
 # Global Variables Declared for this function: LastX, LastY
 # Global Variables Declared for this function: RendererFound
 #
 return unless ($RendererFound);
 #
 $zoomFactor = 1.02 ** (0.5 * ($y - $widget->{LastY}));
 #
 if ($widget->{CurrentCamera}->GetParallelProjection)
  {
   $parallelScale = $widget->{CurrentCamera}->GetParallelScale * $zoomFactor;
   $widget->{CurrentCamera}->SetParallelScale($parallelScale);
  }
 else
  {
   $widget->{CurrentCamera}->Dolly($zoomFactor);
   $CurrentRenderer->ResetCameraClippingRange;
  }
 #
 $widget->{LastX} = $x;
 $widget->{LastY} = $y;
 #
 $widget->_Render;
}
#
#
sub Reset
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $WindowX;
 my $WindowY;
 my $i;
 my $numRenderers;
 my $renderers;
 my @viewport;
 my $vpxmax;
 my $vpxmin;
 my $vpymax;
 my $vpymin;
 my $vx;
 my $vy;
 # Global Variables Declared for this function: CurrentRenderWindow
 # Global Variables Declared for this function: RendererFound
 # Global Variables Declared for this function: CurrentRenderer
 #
 # Get the renderer window dimensions
 $WindowX = $widget->cget('-width');
 $WindowY = $widget->cget('-height');
 #
 # Find which renderer event has occurred in
 $CurrentRenderWindow = $widget->GetRenderWindow;
 $renderers = $CurrentRenderWindow->GetRenderers;
 $numRenderers = $renderers->GetNumberOfItems;
 #
 $renderers->InitTraversal;
 $RendererFound = 0;
 for ($i = 0; $i < $numRenderers; $i += 1)
  {
   $CurrentRenderer = $renderers->GetNextItem;
   $vx = ($x) / $WindowX;
   $vy = ($WindowY - ($y)) / $WindowY;
   #
   @viewport = $CurrentRenderer->GetViewport;
   $vpxmin = $viewport[0];
   $vpymin = $viewport[1];
   $vpxmax = $viewport[2];
   $vpymax = $viewport[3];
   if ($vx >= $vpxmin && $vx <= $vpxmax && $vy >= $vpymin && $vy <= $vpymax)
    {
     $RendererFound = 1;
     last;
    }
  }
 #
 $CurrentRenderer->ResetCamera if ($RendererFound);
 #
 $widget->_Render();
}
#
#
sub Wireframe
{
 my $widget = shift;
 my $actor;
 my $actors;
 # Global Variables Declared for this function: CurrentRenderer
 #
 $actors = $CurrentRenderer->GetActors;
 #
 $actors->InitTraversal;
 $actor = $actors->GetNextItem;
 while( defined($actor)){
        $actor->GetProperty->SetRepresentationToWireframe;
        $actor = $actors->GetNextItem;
 };
 #
 $widget->_Render();
}
#
#
sub Surface
{
 my $widget = shift;
 my $actor;
 my $actors;
 # Global Variables Declared for this function: CurrentRenderer
 #
 $actors = $CurrentRenderer->GetActors;
 #
 $actors->InitTraversal;
 $actor = $actors->GetNextItem;
 while( defined($actor)){
        $actor->GetProperty->SetRepresentationToSurface;
        $actor = $actors->GetNextItem;
 };
 #
 $widget->_Render();
}
#
#
#
sub PickActor   
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $assembly;
 # Global Variables Declared for this function: CurrentRenderer, RendererFound
 # Global Variables Declared for this function: PickedAssembly, PrePickedProperty
 #
 my $WindowY = $widget->cget('-height');
 #
 return unless ($RendererFound);
 $widget->{ActorPicker}->Pick($x,$WindowY - $y - 1,0.0,$CurrentRenderer);
 $assembly = $widget->{ActorPicker}->GetAssembly;
 #
 if ($widget->{PickedAssembly} && $widget->{PrePickedProperty} )
  {
   $widget->{PickedAssembly}->SetProperty($widget->{PrePickedProperty});
   # release hold on the property
   $widget->{PrePickedProperty}->UnRegister($widget->{PrePickedProperty});
   $widget->{PrePickedProperty} = undef;
  }
 #
 if ($assembly )
  {
   $widget->{PickedAssembly} = $assembly;
   $widget->{PrePickedProperty} = $widget->{PickedAssembly}->GetProperty;
   # hold onto the property
   $widget->{PrePickedProperty}->Register($widget->{PrePickedProperty});
   $widget->{PickedAssembly}->SetProperty($widget->{PickedProperty});
  }
 #
 $widget->_Render;
}


1;
__END__
