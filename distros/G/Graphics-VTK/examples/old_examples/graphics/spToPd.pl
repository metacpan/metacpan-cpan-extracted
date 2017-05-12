#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# structured points to geometry
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# read in some structured points
$reader = Graphics::VTK::PNMReader->new;
$reader->SetFileName("$VTK_DATA/B.pgm");
$geometry = Graphics::VTK::StructuredPointsGeometryFilter->new;
$geometry->SetInput($reader->GetOutput);
$geometry->SetExtent(0,10000,0,10000,0,0);
$warp = Graphics::VTK::WarpScalar->new;
$warp->SetInput($geometry->GetOutput);
$warp->SetScaleFactor('-.1');
$mapper = Graphics::VTK::DataSetMapper->new;
$mapper->SetInput($warp->GetOutput);
$mapper->SetScalarRange(0,255);
$mapper->ImmediateModeRenderingOff;
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($actor);
$ren1->GetActiveCamera->Azimuth(20);
$ren1->GetActiveCamera->Elevation(30);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(640,480);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$cam1 = $ren1->GetActiveCamera;
$cam1->Zoom(1.4);
$ren1->ResetCameraClippingRange;
$renWin->Render;
#renWin SetFileName "spToPd.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
