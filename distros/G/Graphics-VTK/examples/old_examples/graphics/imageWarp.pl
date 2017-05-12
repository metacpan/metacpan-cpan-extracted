#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# Mix imaging and visualization; warp an image in z-direction
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInt;
# read in some structured points
$reader = Graphics::VTK::PNMReader->new;
$reader->SetFileName("$VTK_DATA/masonry.ppm");
$luminance = Graphics::VTK::ImageLuminance->new;
$luminance->SetInput($reader->GetOutput);
$geometry = Graphics::VTK::StructuredPointsGeometryFilter->new;
$geometry->SetInput($luminance->GetOutput);
$warp = Graphics::VTK::WarpScalar->new;
$warp->SetInput($geometry->GetOutput);
$warp->SetScaleFactor(-0.1);
# use merge to put back scalars from image file
$merge = Graphics::VTK::MergeFilter->new;
$merge->SetGeometry($warp->GetOutput);
$merge->SetScalars($reader->GetOutput);
$mapper = Graphics::VTK::DataSetMapper->new;
$mapper->SetInput($merge->GetOutput);
$mapper->SetScalarRange(0,255);
$mapper->ImmediateModeRenderingOff;
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
# Create renderer stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($actor);
$ren1->GetActiveCamera->Azimuth(20);
$ren1->GetActiveCamera->Elevation(30);
$ren1->SetBackground(0.1,0.2,0.4);
$ren1->ResetCameraClippingRange;
$renWin->SetSize(450,450);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$cam1 = $ren1->GetActiveCamera;
$cam1->Zoom(1.4);
$renWin->Render;
#renWin SetFileName "valid/imageWarp.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
