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
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ugReader = Graphics::VTK::UGFacetReader->new;
$ugReader->SetFileName("$VTK_DATA/bolt.fac");
$ugReader->MergingOff;
$ugMapper = Graphics::VTK::PolyDataMapper->new;
$ugMapper->SetInput($ugReader->GetOutput);
$ugActor = Graphics::VTK::Actor->new;
$ugActor->SetMapper($ugMapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($ugActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(500,500);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$cam1 = $ren1->GetActiveCamera;
$cam1->Elevation(210);
$cam1->Azimuth(30);
$ren1->ResetCameraClippingRange;
$renWin->Render;
#renWin SetFileName "ugFacet.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
