#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version of the Mace example
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$tss = Graphics::VTK::TexturedSphereSource->new;
$tss->SetThetaResolution(18);
$tss->SetPhiResolution(9);
$earthMapper = Graphics::VTK::PolyDataMapper->new;
$earthMapper->SetInput($tss->GetOutput);
$earthActor = Graphics::VTK::Actor->new;
$earthActor->SetMapper($earthMapper);
# load in the texture map
$atext = Graphics::VTK::Texture->new;
$pnmReader = Graphics::VTK::PNMReader->new;
$pnmReader->SetFileName("$VTK_DATA/earth.ppm");
$atext->SetInput($pnmReader->GetOutput);
$atext->InterpolateOn;
$earthActor->SetTexture($atext);
# create a earth source and actor
$es = Graphics::VTK::EarthSource->new;
$es->SetRadius(0.501);
$es->SetOnRatio(2);
$earth2Mapper = Graphics::VTK::PolyDataMapper->new;
$earth2Mapper->SetInput($es->GetOutput);
$earth2Actor = Graphics::VTK::Actor->new;
$earth2Actor->SetMapper($earth2Mapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($earthActor);
$ren1->AddActor($earth2Actor);
$ren1->SetBackground(0,0,0.1);
$renWin->SetSize(300,300);
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
#renWin SetFileName "earth.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
