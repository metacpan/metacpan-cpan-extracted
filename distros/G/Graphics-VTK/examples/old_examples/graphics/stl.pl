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
$sr = Graphics::VTK::STLReader->new;
$sr->SetFileName("$VTK_DATA/42400-IDGH.stl");
$stlMapper = Graphics::VTK::PolyDataMapper->new;
$stlMapper->SetInput($sr->GetOutput);
$stlActor = Graphics::VTK::LODActor->new;
$stlActor->SetMapper($stlMapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($stlActor);
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
$cam1->Zoom(1.4);
$iren->Initialize;
#renWin SetFileName "stl.tcl.ppm"
#renWin SaveImageAsPPM
# test regeneration of the LODMappers
$stlActor->Modified;
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
