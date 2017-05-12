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
# load in the texture map
$pnmReader = Graphics::VTK::PNMReader->new;
$pnmReader->SetFileName("$VTK_DATA/masonry.ppm");
$gf = Graphics::VTK::GeometryFilter->new;
$gf->SetInput($pnmReader->GetOutput);
$wl = Graphics::VTK::WarpLens->new;
$wl->SetInput($gf->GetOutput);
$wl->SetCenter(127.5,127.5);
$wl->SetKappa('-6.0e-6');
$tf = Graphics::VTK::TriangleFilter->new;
$tf->SetInput($wl->GetPolyDataOutput);
$strip = Graphics::VTK::Stripper->new;
$strip->SetInput($tf->GetOutput);
$dsm = Graphics::VTK::PolyDataMapper->new;
$dsm->SetInput($strip->GetOutput);
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($dsm);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($planeActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(500,500);
# render the image
$iren->Initialize;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
$ren1->GetActiveCamera->Zoom(1.4);
$renWin->Render;
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
