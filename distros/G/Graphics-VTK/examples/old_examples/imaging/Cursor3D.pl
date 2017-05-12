#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
#source $VTK_TCL/WidgetObject.tcl
# This script uses a vtkTkRenderWidget to create a
# Tk widget that is associated with a vtkRenderWindow.
$source->______graphics_examplesTcl_TkInteractor_tcl;
$source->______imaging_examplesTcl_TkImageViewerInteractor_tcl;
# This little example shows how a cursor can be created in 
# image viewers, and renderers.  The standard TkImageViewerWidget and
# TkRenderWidget bindings are used.  There is a new binding:
# middle button in the image viewer sets the position of the cursor.  
# global values
$CURSOR_X = 20;
$CURSOR_Y = 20;
$CURSOR_Z = 20;
$IMAGE_MAG_X = 4;
$IMAGE_MAG_Y = 4;
$IMAGE_MAG_Z = 1;
# Create the GUI: two renderer widgets and a quit button
$MW->withdraw;
$MW->{'.top'} = $MW->Toplevel;
$help = $MW->{'.top.help'} = $MW->{'.top'}->Label('-text',"MiddleMouse (or shift-LeftMouse) in image viewer to place cursor");
$displayFrame = $MW->{'.top.f1'} = $MW->{'.top'}->Frame;
$quitButton = $MW->{'.top.btn'} = $MW->{'.top'}->Button('-text','Quit','-command',
 sub
  {
   exit();
  }
);
foreach $_ (())
 {
  $_->pack;
 }
$displayFrame->pack('-fill','both','-expand','t');
$quitButton->pack('-fill','x');
$viewerFrame = $displayFrame->{'.vFm'} = $displayFrame->Frame;
$rendererFrame = $displayFrame->{'.rFm'} = $displayFrame->Frame;
$viewerFrame->pack('-padx',3,'-pady',3,'-side','left','-fill','both','-expand','f');
$rendererFrame->pack('-padx',3,'-pady',3,'-side','left','-fill','both','-expand','t');
$viewerWidget = $viewerFrame->{'.v'} = $viewerFrame->vtkImageViewer('-width',264,'-height',264);
$viewerControls = $viewerFrame->{'.c'} = $viewerFrame->Frame;
foreach $_ (($viewerControls,$viewerWidget))
 {
  $_->pack('-side','bottom','-fill','both','-expand','f');
 }
$downButton = $viewerControls->{'.down'} = $viewerControls->Button('-text',"Down",'-command',"ViewerDown");
$upButton = $viewerControls->{'.up'} = $viewerControls->Button('-text',"Up",'-command',"ViewerUp");
$sliceLabel = $viewerControls->{'.slice'} = $viewerControls->Label('-text',"slice: [expr $CURSOR_Z * $IMAGE_MAG_Z]");
foreach $_ (($downButton,$upButton,$sliceLabel))
 {
  $_->pack('-side','left','-expand','t','-fill','both');
 }
$renWin = Graphics::VTK::RenderWindow->new;
$renderWidget = $rendererFrame = Graphics::VTK::TkRenderWidget->new('.r','-width',264,'-height',264,'-rw',$renWin);
$renderWidget->pack('-side','top');
# pipeline stuff
$reader = Graphics::VTK::SLCReader->new;
$reader->SetFileName("$VTK_DATA/poship.slc");
# cursor stuff
$magnify = Graphics::VTK::ImageMagnify->new;
$magnify->SetInput($reader->GetOutput);
$magnify->SetMagnificationFactors($IMAGE_MAG_X,$IMAGE_MAG_Y,$IMAGE_MAG_Z);
$imageCursor = Graphics::VTK::ImageCursor3D->new;
$imageCursor->SetInput($magnify->GetOutput);
$imageCursor->SetCursorPosition($CURSOR_X * $IMAGE_MAG_X,$CURSOR_Y * $IMAGE_MAG_Y,$CURSOR_Z * $IMAGE_MAG_Z);
$imageCursor->SetCursorValue(255);
$imageCursor->SetCursorRadius(50 * $IMAGE_MAG_X);
$axes = Graphics::VTK::Axes->new;
$axes->SymmetricOn;
$axes->SetOrigin($CURSOR_X,$CURSOR_Y,$CURSOR_Z);
$axes->SetScaleFactor(50.0);
$axesMapper = Graphics::VTK::PolyDataMapper->new;
$axesMapper->SetInput($axes->GetOutput);
$axesActor = Graphics::VTK::Actor->new;
$axesActor->SetMapper($axesMapper);
$axesActor->GetProperty->SetAmbient(0.5);
# image viewer stuff
$viewer = $viewerWidget->GetImageViewer;
$viewer->SetInput($imageCursor->GetOutput);
$viewer->SetZSlice($CURSOR_Z * $IMAGE_MAG_Z);
$viewer->SetColorWindow(256);
$viewer->SetColorLevel(128);
# Create transfer functions for opacity and color
$opacityTransferFunction = Graphics::VTK::PiecewiseFunction->new;
$opacityTransferFunction->AddPoint(20,0.0);
$opacityTransferFunction->AddPoint(255,0.2);
$colorTransferFunction = Graphics::VTK::ColorTransferFunction->new;
$colorTransferFunction->AddRedPoint(0.0,0.0);
$colorTransferFunction->AddRedPoint(64.0,1.0);
$colorTransferFunction->AddRedPoint(128.0,0.0);
$colorTransferFunction->AddRedPoint(255.0,0.0);
$colorTransferFunction->AddBluePoint(0.0,0.0);
$colorTransferFunction->AddBluePoint(64.0,0.0);
$colorTransferFunction->AddBluePoint(128.0,1.0);
$colorTransferFunction->AddBluePoint(192.0,0.0);
$colorTransferFunction->AddBluePoint(255.0,0.0);
$colorTransferFunction->AddGreenPoint(0.0,0.0);
$colorTransferFunction->AddGreenPoint(128.0,0.0);
$colorTransferFunction->AddGreenPoint(192.0,1.0);
$colorTransferFunction->AddGreenPoint(255.0,0.2);
# Create properties, mappers, volume actors, and ray cast function
$volumeProperty = Graphics::VTK::VolumeProperty->new;
$volumeProperty->SetColor(@Graphics::VTK::Colors::colorTransferFunction);
$volumeProperty->SetScalarOpacity($opacityTransferFunction);
$compositeFunction = Graphics::VTK::VolumeRayCastCompositeFunction->new;
$volumeMapper = Graphics::VTK::VolumeRayCastMapper->new;
$volumeMapper->SetInput($reader->GetOutput);
$volumeMapper->SetVolumeRayCastFunction($compositeFunction);
$volume = Graphics::VTK::Volume->new;
$volume->SetMapper($volumeMapper);
$volume->SetProperty($volumeProperty);
# Create outline
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($reader->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(1,1,1);
# create the renderer
$ren1 = Graphics::VTK::Renderer->new;
$renWin = $renderWidget->GetRenderWindow;
$renWin->AddRenderer($ren1);
$renWin->SetSize(256,256);
$ren1->AddActor($axesActor);
$ren1->AddVolume($volume);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->Render;
#
sub TkCheckAbort
{
 my $foo;
 # Global Variables Declared for this function: renWin
 $foo = $renWin->GetEventPending;
 $renWin->SetAbortRender(1) if ($foo != 0);
}
$renWin->SetAbortCheckMethod(
 sub
  {
   TkCheckAbort();
  }
);
#BindTkImageViewer $viewerWidget
#BindTkRenderWidget $renderWidget
# lets ass an extra binding of the middle button in the image viewer
# to set the cursor location
$viewerWidget->bind('<Button-2>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   SetCursorFromViewer($Ev->x,$Ev->y);
  }
);
$viewerWidget->bind('<Shift-Button-1>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   SetCursorFromViewer($Ev->x,$Ev->y);
  }
);
# supporting procedures
#
sub ViewerDown
{
 my $ViewerSetZSlice;
 my $z;
 # Global Variables Declared for this function: viewer
 $z = $viewer->GetZSlice;
 ViewerSetZSlice($viewer,$z - 1);
}
#
sub ViewerUp
{
 my $ViewerSetZSlice;
 my $z;
 # Global Variables Declared for this function: viewer
 $z = $viewer->GetZSlice;
 ViewerSetZSlice($viewer,$z + 1);
}
#
sub ViewerSetZSlice
{
 my $viewer = shift;
 my $z = shift;
 # Global Variables Declared for this function: sliceLabel
 $viewer->SetZSlice($z);
 $sliceLabel->configure('-text',"slice: $z");
 $viewer->Render;
}
#
sub SetCursorFromViewer
{
 my $x = shift;
 my $y = shift;
 my $SetCursor;
 my $height;
 my $z;
 # Global Variables Declared for this function: viewer, viewerWidget
 # Global Variables Declared for this function: IMAGE_MAG_X, IMAGE_MAG_Y, IMAGE_MAG_Z
 # we have to flip y axis because tk uses upper right origin.
 $height = ($viewerWidget->configure('-height'))[4];
 $y = $height - $y;
 $z = $viewer->GetZSlice;
 SetCursor($x / $IMAGE_MAG_X,$y / $IMAGE_MAG_Y,$z / $IMAGE_MAG_Z);
}
#
sub SetCursor
{
 my $x = shift;
 my $y = shift;
 my $z = shift;
 # Global Variables Declared for this function: viewer, renWin
 # Global Variables Declared for this function: CURSOR_X, CURSOR_Y, CURSOR_Z, IMAGE_MAG_X, IMAGE_MAG_Y, IMAGE_MAG_Z
 $CURSOR_X = $x;
 $CURSOR_Y = $y;
 $CURSOR_Z = $z;
 $axes->SetOrigin($CURSOR_X,$CURSOR_Y,$CURSOR_Z);
 $imageCursor->SetCursorPosition($CURSOR_X * $IMAGE_MAG_X,$CURSOR_Y * $IMAGE_MAG_Y,$CURSOR_Z * $IMAGE_MAG_Z);
 $viewer->Render;
 $renWin->Render;
}
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
