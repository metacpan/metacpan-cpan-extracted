#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;


# This simple example shows how to do basic texture mapping.

# We start off by loading some Tcl modules. One is the basic VTK library
# the other is a package for rendering.

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# Load in the texture map. A texture is any unsigned char image. If it
# is not of this type, you will have to map it through a lookup table
# or by using vtkImageShiftScale.

$bmpReader = Graphics::VTK::BMPReader->new;
$bmpReader->SetFileName("$VTK_DATA_ROOT/Data/masonry.bmp");
$atext = Graphics::VTK::Texture->new;
$atext->SetInput($bmpReader->GetOutput);
$atext->InterpolateOn;

# Create a plane source and actor. The vtkPlanesSource generates 
# texture coordinates.

$plane = Graphics::VTK::PlaneSource->new;
$planeMapper = Graphics::VTK::PolyDataMapper->new;
$planeMapper->SetInput($plane->GetOutput);
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($planeMapper);
$planeActor->SetTexture($atext);

# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the renderer, set the background and size
$ren1->AddActor($planeActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(500,500);

# render the image
$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;

$cam1 = $ren1->GetActiveCamera;
$cam1->Elevation(-30);
$cam1->Roll(-20);
$ren1->ResetCameraClippingRange;
$renWin->Render;

# prevent the tk window from showing up then start the event loop
$MW->withdraw;





Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
