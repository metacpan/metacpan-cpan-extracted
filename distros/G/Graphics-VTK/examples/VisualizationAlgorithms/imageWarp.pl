#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example shows how to combine data from both the imaging
# and graphics pipelines. The vtkMergeData filter is used to
# merge the data from each together.

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# Read in an image and compute a luminance value. The image is extracted
# as a set of polygons (vtkImageDataGeometryFilter). We then will
# warp the plane using the scalar (luminance) values.

$reader = Graphics::VTK::BMPReader->new;
$reader->SetFileName("$VTK_DATA_ROOT/Data/masonry.bmp");
$luminance = Graphics::VTK::ImageLuminance->new;
$luminance->SetInput($reader->GetOutput);
$geometry = Graphics::VTK::ImageDataGeometryFilter->new;
$geometry->SetInput($luminance->GetOutput);
$warp = Graphics::VTK::WarpScalar->new;
$warp->SetInput($geometry->GetOutput);
$warp->SetScaleFactor(-0.1);

# Use vtkMergeFilter to combine the original image with the warped geometry.

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

$renWin->SetSize(250,250);

# render the image

$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$cam1 = $ren1->GetActiveCamera;
$cam1->Zoom(1.4);
$renWin->Render;

# prevent the tk window from showing up then start the event loop
$MW->withdraw;


Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
