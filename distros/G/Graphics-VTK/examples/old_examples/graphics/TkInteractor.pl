#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;

$MW = Tk::MainWindow->new;

## Procedure should be called to set bindings and initialize variables
#
$catch->source_______examplesTcl_vtkInt_tcl;
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
$catch->source__VTK_TCL_WidgetObject_tcl;
#
$TkInteractor_StartRenderMethod = "";
$TkInteractor_EndRenderMethod = "";
$TkInteractor_InteractiveUpdateRate = 15.0;
$TkInteractor_StillUpdateRate = 0.1;
#
#
sub BindTkRenderWidget
{
 my $widget = shift;
 my $EndMotion;
 my $Enter;
 my $Expose;
 my $Pan;
 my $PickActor;
 my $Reset;
 my $Rotate;
 my $RubberZoom;
 my $StartMotion;
 my $Surface;
 my $Wireframe;
 my $Zoom;
 my $focus;
 $widget->bind('<Any-ButtonPress>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    StartMotion($Ev->W,$Ev->x,$Ev->y);
   }
 );
 $widget->bind('<Any-ButtonRelease>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    EndMotion($Ev->W,$Ev->x,$Ev->y);
   }
 );
 $widget->bind('<B1-Motion>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    Rotate($Ev->W,$Ev->x,$Ev->y);
   }
 );
 $widget->bind('<B2-Motion>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    Pan($Ev->W,$Ev->x,$Ev->y);
   }
 );
 $widget->bind('<B3-Motion>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    Zoom($Ev->W,$Ev->x,$Ev->y);
   }
 );
 $widget->bind('<Shift-B1-Motion>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    Pan($Ev->W,$Ev->x,$Ev->y);
   }
 );
 $widget->bind('<Shift-B3-Motion>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    RubberZoom($Ev->W,$Ev->x,$Ev->y);
   }
 );
 $widget->bind('<KeyPress-r>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    Reset($Ev->W,$Ev->x,$Ev->y);
   }
 );
 $widget->bind('<KeyPress-u>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $MW->{'.vtkInteract'}->MainWindow->deiconify;
   }
 );
 $widget->bind('<KeyPress-w>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    Wireframe($Ev->W);
   }
 );
 $widget->bind('<KeyPress-s>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    Surface($Ev->W);
   }
 );
 $widget->bind('<KeyPress-p>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    PickActor($Ev->W,$Ev->x,$Ev->y);
   }
 );
 $widget->bind('<Enter>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    Enter($Ev->W,$Ev->x,$Ev->y);
   }
 );
 $widget->bind('<Leave>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    $focus->_oldFocus;
   }
 );
 $widget->bind('<Expose>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    Expose($Ev->W);
   }
 );
}
#
# a litle more complex than just "bind $widget <Expose> {%W Render}"
# we have to handle all pending expose events otherwise they que up.
#
sub Expose
{
 my $widget = shift;
 my $GetWidgetVariableValue;
 my $SetWidgetVariableValue;
 my $return;
 # Global Variables Declared for this function: TkInteractor_StillUpdateRate
 return if ($GetWidgetVariableValue->_widget('InExpose') == 1);
 $SetWidgetVariableValue->_widget('InExpose',1);
 $widget->GetRenderWindow->SetDesiredUpdateRate($TkInteractor_StillUpdateRate);
 $MW->update;
 $widget->GetRenderWindow->Render;
 $SetWidgetVariableValue->_widget('InExpose',0);
}
#
# Global variable keeps track of whether active renderer was found
$RendererFound = 0;
#
# Create event bindings
#
#
sub Render
{
 my $widget = shift;
 my $if;
 # Global Variables Declared for this function: CurrentCamera, CurrentLight
 # Global Variables Declared for this function: TkInteractor_StartRenderMethod
 # Global Variables Declared for this function: TkInteractor_EndRenderMethod
 #
 $if->__TkInteractor_StartRenderMethod_______("
	$TkInteractor_StartRenderMethod
    ");
 #
 $CurrentLight->SetPosition($CurrentCamera->GetPosition);
 $CurrentLight->SetFocalPoint($CurrentCamera->GetFocalPoint);
 #
 $widget->Render;
 #
 $if->__TkInteractor_EndRenderMethod_______("
	$TkInteractor_EndRenderMethod
    ");
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
 my $viewport;
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
 $WindowX = ($widget->configure('-width'))[4];
 $WindowY = ($widget->configure('-height'))[4];
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
   $viewport = $CurrentRenderer->GetViewport;
   $vpxmin = $viewport[0];
   $vpymin = $viewport[1];
   $vpxmax = $viewport[2];
   $vpymax = $viewport[3];
   if ($vx >= $vpxmin && $vx <= $vpxmax && $vy >= $vpymin && $vy <= $vpymax)
    {
     $RendererFound = 1;
     $WindowCenterX = ($WindowX) * (($vpxmax - $vpxmin) / 2.0 + $vpxmin);
     $WindowCenterY = ($WindowY) * (($vpymax - $vpymin) / 2.0 + $vpymin);
     break();
    }
  }
 #
 $CurrentCamera = $CurrentRenderer->GetActiveCamera;
 $lights = $CurrentRenderer->GetLights;
 $lights->InitTraversal;
 $CurrentLight = $lights->GetNextItem;
 #
 $LastX = $x;
 $LastY = $y;
}
#
#
sub Enter
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $UpdateRenderer;
 my $focus;
 # Global Variables Declared for this function: oldFocus
 #
 $oldFocus = focus();
 $focus->_widget;
 UpdateRenderer($widget,$x,$y);
}
#
#
sub StartMotion
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $UpdateRenderer;
 my $return;
 # Global Variables Declared for this function: CurrentCamera, CurrentLight
 # Global Variables Declared for this function: CurrentRenderWindow, CurrentRenderer
 # Global Variables Declared for this function: LastX, LastY
 # Global Variables Declared for this function: RendererFound
 # Global Variables Declared for this function: TkInteractor_InteractiveUpdateRate
 # Global Variables Declared for this function: RubberZoomPerformed
 #
 UpdateRenderer($widget,$x,$y);
 return unless ($RendererFound);
 #
 $RubberZoomPerformed = 0;
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
 my $DoRubberZoom;
 my $Render;
 my $return;
 # Global Variables Declared for this function: CurrentRenderWindow
 # Global Variables Declared for this function: RendererFound
 # Global Variables Declared for this function: TkInteractor_StillUpdateRate
 # Global Variables Declared for this function: RubberZoomPerformed
 # Global Variables Declared for this function: CurrentRenderer
 #
 return unless ($RendererFound);
 $CurrentRenderWindow->SetDesiredUpdateRate($TkInteractor_StillUpdateRate);
 #
 #
 if ($RubberZoomPerformed)
  {
   $CurrentRenderer->RemoveProp('RubberBandActor');
   DoRubberZoom($widget);
  }
 #
 Render($widget);
}
#
# Objects used to display rubberband
$RubberBandPoints = Graphics::VTK::Points->new;
$RubberBandLines = Graphics::VTK::CellArray->new;
$RubberBandScalars = Graphics::VTK::Scalars->new;
$RubberBandPolyData = Graphics::VTK::PolyData->new;
$RubberBandMapper = Graphics::VTK::PolyDataMapper2D->new;
$RubberBandActor = Graphics::VTK::Actor2D->new;
$RubberBandColors = Graphics::VTK::LookupTable->new;
#
$RubberBandPolyData->SetPoints($RubberBandPoints);
$RubberBandPolyData->SetLines($RubberBandLines);
$RubberBandMapper->SetInput($RubberBandPolyData);
$RubberBandMapper->SetLookupTable($RubberBandColors);
$RubberBandActor->SetMapper($RubberBandMapper);
#
$RubberBandColors->SetNumberOfTableValues(2);
$RubberBandColors->SetNumberOfColors(2);
$RubberBandColors->SetTableValue(0,1.0,0.0,0.0,1.0);
$RubberBandColors->SetTableValue(1,1.0,1.0,1.0,1.0);
#
$RubberBandPolyData->GetPointData->SetScalars($RubberBandScalars);
#
$RubberBandMapper->SetScalarRange(0,1);
#
$RubberBandPoints->InsertPoint(0,0,0,0);
$RubberBandPoints->InsertPoint(1,0,10,0);
$RubberBandPoints->InsertPoint(2,10,10,0);
$RubberBandPoints->InsertPoint(3,10,0,0);
#
$RubberBandLines->InsertNextCell(5);
$RubberBandLines->InsertCellPoint(0);
$RubberBandLines->InsertCellPoint(1);
$RubberBandLines->InsertCellPoint(2);
$RubberBandLines->InsertCellPoint(3);
$RubberBandLines->InsertCellPoint(0);
#
$RubberBandScalars->InsertNextScalar(0);
$RubberBandScalars->InsertNextScalar(1);
$RubberBandScalars->InsertNextScalar(0);
$RubberBandScalars->InsertNextScalar(1);
#
$RubberBandMapper->ScalarVisibilityOn;
#
# Called when the mouse button is release - do the zoom
#
sub DoRubberZoom
{
 my $widget = shift;
 my $DPoint;
 my $FPoint;
 my $FPoint0;
 my $FPoint1;
 my $FPoint2;
 my $PPoint;
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
 my $focalEdge;
 my $focalEdge0;
 my $focalEdge1;
 my $focalEdge2;
 my $focalEdge3;
 my $nearFocalPoint;
 my $nearFocalPoint0;
 my $nearFocalPoint1;
 my $nearFocalPoint2;
 my $nearFocalPoint3;
 my $nearplane;
 my $newFocalPoint;
 my $newFocalPoint0;
 my $newFocalPoint1;
 my $newFocalPoint2;
 my $newFocalPoint3;
 my $newPosition;
 my $newPosition0;
 my $newPosition1;
 my $newPosition2;
 my $newPosition3;
 my $newScale;
 my $positionDepth;
 my $range;
 my $return;
 my $ydiff;
 my $ydist;
 # Global Variables Declared for this function: CurrentCamera, CurrentRenderer
 # Global Variables Declared for this function: RendererFound
 # Global Variables Declared for this function: StartRubberZoomX, StartRubberZoomY
 # Global Variables Declared for this function: EndRubberZoomX, EndRubberZoomY
 #
 # Return if there is no renderer, or the rubber band is less
 # that 5 pixels in either direction
 return unless ($RendererFound);
 return if ($StartRubberZoomX - $EndRubberZoomX < 5 && $StartRubberZoomX - $EndRubberZoomX > -5);
 return if ($StartRubberZoomY - $EndRubberZoomY < 5 && $StartRubberZoomY - $EndRubberZoomY > -5);
 #
 # We'll need the window height later
 $WindowY = ($widget->configure('-height'))[4];
 #
 # What is the center of the rubber band box in pixels?
 $centerX = ($StartRubberZoomX + $EndRubberZoomX) / 2.0;
 $centerY = ($StartRubberZoomY + $EndRubberZoomY) / 2.0;
 #
 # Convert the focal point to a display coordinate in order to get the
 # depth of the focal point in display units
 $FPoint = $CurrentCamera->GetFocalPoint;
 $FPoint0 = $FPoint[0];
 $FPoint1 = $FPoint[1];
 $FPoint2 = $FPoint[2];
 $CurrentRenderer->SetWorldPoint($FPoint0,$FPoint1,$FPoint2,1.0);
 $CurrentRenderer->WorldToDisplay;
 $DPoint = $CurrentRenderer->GetDisplayPoint;
 $focalDepth = $DPoint[2];
 #
 # Convert the position of the camera to a display coordinate in order
 # to get the depth of the camera in display coordinates. Note this is
 # a negative number (behind the near clipping plane of 0) but it works
 # ok anyway
 $PPoint = $CurrentCamera->GetPosition;
 $PPoint0 = $PPoint[0];
 $PPoint1 = $PPoint[1];
 $PPoint2 = $PPoint[2];
 $CurrentRenderer->SetWorldPoint($PPoint0,$PPoint1,$PPoint2,1.0);
 $CurrentRenderer->WorldToDisplay;
 $DPoint = $CurrentRenderer->GetDisplayPoint;
 $positionDepth = $DPoint[2];
 #
 # Find out the world position of where our new focal point should
 # be - it will be at the center of the box, back at the same focal depth
 # Don't actually set it now - we need to do all our computations before
 # we modify the camera
 $CurrentRenderer->SetDisplayPoint($centerX,$centerY,$focalDepth);
 $CurrentRenderer->DisplayToWorld;
 $newFocalPoint = $CurrentRenderer->GetWorldPoint;
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
 $newPosition = $CurrentRenderer->GetWorldPoint;
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
 if ($CurrentCamera->GetParallelProjection)
  {
   # the new scale is just based on the y size of the rubber band box
   # compared to the y size of the window
   $ydiff = $StartRubberZoomX - $EndRubberZoomX;
   $ydiff = $ydiff * -1.0 if ($ydiff < 0.0);
   $newScale = $CurrentCamera->GetParallelScale;
   $newScale = $newScale * $ydiff / $WindowY;
   #
   # now we can actually modify the camera
   $CurrentCamera->SetFocalPoint($newFocalPoint0,$newFocalPoint1,$newFocalPoint2);
   $CurrentCamera->SetPosition($newPosition0,$newPosition1,$newPosition2);
   $CurrentCamera->SetParallelScale($newScale);
   #
  }
 else
  {
   # find out the center of the rubber band box on the near plane
   $CurrentRenderer->SetDisplayPoint($centerX,$centerY,0.0);
   $CurrentRenderer->DisplayToWorld;
   $nearFocalPoint = $CurrentRenderer->GetWorldPoint;
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
   $CurrentRenderer->SetDisplayPoint($centerX,$StartRubberZoomY,0.0);
   $CurrentRenderer->DisplayToWorld;
   $focalEdge = $CurrentRenderer->GetWorldPoint;
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
   $angle = 0.5 * 3.141592 / 180.0 * $CurrentCamera->GetViewAngle;
   $d = $ydist / tan($angle);
   $range = $CurrentCamera->GetClippingRange;
   $nearplane = $range[0];
   $factor = $CurrentCamera->GetDistance / ($CurrentCamera->GetDistance - $nearplane + $d);
   #
   # now we can actually modify the camera
   $CurrentCamera->SetFocalPoint($newFocalPoint0,$newFocalPoint1,$newFocalPoint2);
   $CurrentCamera->SetPosition($newPosition0,$newPosition1,$newPosition2);
   $CurrentCamera->Dolly($factor);
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
 my $Render;
 my $return;
 # Global Variables Declared for this function: CurrentCamera
 # Global Variables Declared for this function: LastX, LastY
 # Global Variables Declared for this function: RendererFound
 #
 return unless ($RendererFound);
 #
 $CurrentCamera->Azimuth($LastX - $x);
 $CurrentCamera->Elevation($y - $LastY);
 $CurrentCamera->OrthogonalizeViewUp;
 #
 $LastX = $x;
 $LastY = $y;
 #
 Render($widget);
}
#
#
sub RubberZoom
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $Render;
 my $WindowY;
 my $return;
 # Global Variables Declared for this function: RendererFound
 # Global Variables Declared for this function: CurrentRenderer
 # Global Variables Declared for this function: RubberZoomPerformed
 # Global Variables Declared for this function: LastX, LastY
 # Global Variables Declared for this function: StartRubberZoomX, StartRubberZoomY
 # Global Variables Declared for this function: EndRubberZoomX, EndRubberZoomY
 #
 return unless ($RendererFound);
 #
 $WindowY = ($widget->configure('-height'))[4];
 #
 unless ($RubberZoomPerformed)
  {
   $CurrentRenderer->AddProp($RubberBandActor);
   #
   $StartRubberZoomX = $x;
   $StartRubberZoomY = $WindowY - $y - 1;
   #
   $RubberZoomPerformed = 1;
  }
 #
 $EndRubberZoomX = $x;
 $EndRubberZoomY = $WindowY - $y - 1;
 #
 $RubberBandPoints->SetPoint(0,$StartRubberZoomX,$StartRubberZoomY,0);
 $RubberBandPoints->SetPoint(1,$StartRubberZoomX,$EndRubberZoomY,0);
 $RubberBandPoints->SetPoint(2,$EndRubberZoomX,$EndRubberZoomY,0);
 $RubberBandPoints->SetPoint(3,$EndRubberZoomX,$StartRubberZoomY,0);
 #
 Render($widget);
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
 my $DPoint;
 my $FPoint;
 my $FPoint0;
 my $FPoint1;
 my $FPoint2;
 my $PPoint;
 my $PPoint0;
 my $PPoint1;
 my $PPoint2;
 my $RPoint;
 my $RPoint0;
 my $RPoint1;
 my $RPoint2;
 my $RPoint3;
 my $Render;
 my $focalDepth;
 my $return;
 # Global Variables Declared for this function: CurrentRenderer, CurrentCamera
 # Global Variables Declared for this function: WindowCenterX, WindowCenterY, LastX, LastY
 # Global Variables Declared for this function: RendererFound
 #
 return unless ($RendererFound);
 #
 $FPoint = $CurrentCamera->GetFocalPoint;
 $FPoint0 = $FPoint[0];
 $FPoint1 = $FPoint[1];
 $FPoint2 = $FPoint[2];
 #
 $PPoint = $CurrentCamera->GetPosition;
 $PPoint0 = $PPoint[0];
 $PPoint1 = $PPoint[1];
 $PPoint2 = $PPoint[2];
 #
 $CurrentRenderer->SetWorldPoint($FPoint0,$FPoint1,$FPoint2,1.0);
 $CurrentRenderer->WorldToDisplay;
 $DPoint = $CurrentRenderer->GetDisplayPoint;
 $focalDepth = $DPoint[2];
 #
 $APoint0 = $WindowCenterX + $x - $LastX;
 $APoint1 = $WindowCenterY - $y - $LastY;
 #
 $CurrentRenderer->SetDisplayPoint($APoint0,$APoint1,$focalDepth);
 $CurrentRenderer->DisplayToWorld;
 $RPoint = $CurrentRenderer->GetWorldPoint;
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
 $CurrentCamera->SetFocalPoint(($FPoint0 - $RPoint0) / 2.0 + $FPoint0,($FPoint1 - $RPoint1) / 2.0 + $FPoint1,($FPoint2 - $RPoint2) / 2.0 + $FPoint2);
 #
 $CurrentCamera->SetPosition(($FPoint0 - $RPoint0) / 2.0 + $PPoint0,($FPoint1 - $RPoint1) / 2.0 + $PPoint1,($FPoint2 - $RPoint2) / 2.0 + $PPoint2);
 #
 $LastX = $x;
 $LastY = $y;
 #
 Render($widget);
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
 $zoomFactor = 1.02 ** (0.5 * ($y - $LastY));
 #
 if ($CurrentCamera->GetParallelProjection)
  {
   $parallelScale = $CurrentCamera->GetParallelScale * $zoomFactor;
   $CurrentCamera->SetParallelScale($parallelScale);
  }
 else
  {
   $CurrentCamera->Dolly($zoomFactor);
   $CurrentRenderer->ResetCameraClippingRange;
  }
 #
 $LastX = $x;
 $LastY = $y;
 #
 Render($widget);
}
#
#
sub Reset
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $Render;
 my $WindowX;
 my $WindowY;
 my $break;
 my $i;
 my $numRenderers;
 my $renderers;
 my $viewport;
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
 $WindowX = ($widget->configure('-width'))[4];
 $WindowY = ($widget->configure('-height'))[4];
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
   $viewport = $CurrentRenderer->GetViewport;
   $vpxmin = $viewport[0];
   $vpymin = $viewport[1];
   $vpxmax = $viewport[2];
   $vpymax = $viewport[3];
   if ($vx >= $vpxmin && $vx <= $vpxmax && $vy >= $vpymin && $vy <= $vpymax)
    {
     $RendererFound = 1;
     break();
    }
  }
 #
 $CurrentRenderer->ResetCamera if ($RendererFound);
 #
 Render($widget);
}
#
#
sub Wireframe
{
 my $widget = shift;
 my $Render;
 my $actor;
 my $actors;
 my $while;
 # Global Variables Declared for this function: CurrentRenderer
 #
 $actors = $CurrentRenderer->GetActors;
 #
 $actors->InitTraversal;
 $actor = $actors->GetNextItem;
 $while->__actor_______("
        [$actor GetProperty] SetRepresentationToWireframe
        set actor [$actors GetNextItem]
    ");
 #
 Render($widget);
}
#
#
sub Surface
{
 my $widget = shift;
 my $Render;
 my $actor;
 my $actors;
 my $while;
 # Global Variables Declared for this function: CurrentRenderer
 #
 $actors = $CurrentRenderer->GetActors;
 #
 $actors->InitTraversal;
 $actor = $actors->GetNextItem;
 $while->__actor_______("
        [$actor GetProperty] SetRepresentationToSurface
        set actor [$actors GetNextItem]
    ");
 #
 Render($widget);
}
#
# Used to support picking operations
#
$PickedAssembly = "";
$ActorPicker = Graphics::VTK::CellPicker->new;
$PickedProperty = Graphics::VTK::Property->new;
$PickedProperty->SetColor(1,0,0);
$PrePickedProperty = "";
#
#
sub PickActor
{
 my $widget = shift;
 my $x = shift;
 my $y = shift;
 my $Render;
 my $assembly;
 my $return;
 # Global Variables Declared for this function: CurrentRenderer, RendererFound
 # Global Variables Declared for this function: PickedAssembly, PrePickedProperty, WindowY
 #
 $WindowY = ($widget->configure('-height'))[4];
 #
 return unless ($RendererFound);
 $ActorPicker->Pick($x,$WindowY - $y - 1,0.0,$CurrentRenderer);
 $assembly = $ActorPicker->GetAssembly;
 #
 if ($PickedAssembly ne "" && $PrePickedProperty ne "")
  {
   $PickedAssembly->SetProperty($PrePickedProperty);
   # release hold on the property
   $PrePickedProperty->UnRegister($PrePickedProperty);
   $PrePickedProperty = "";
  }
 #
 if ($assembly ne "")
  {
   $PickedAssembly = $assembly;
   $PrePickedProperty = $PickedAssembly->GetProperty;
   # hold onto the property
   $PrePickedProperty->Register($PrePickedProperty);
   $PickedAssembly->SetProperty($PickedProperty);
  }
 #
 Render($widget);
}
