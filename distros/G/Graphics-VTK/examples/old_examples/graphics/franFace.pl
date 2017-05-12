#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version of old franFace
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create a cyberware source
$cyber = Graphics::VTK::PolyDataReader->new;
$cyber->SetFileName("$VTK_DATA/fran_cut.vtk");
$cyberMapper = Graphics::VTK::PolyDataMapper->new;
$cyberMapper->SetInput($cyber->GetOutput);
$pnm1 = Graphics::VTK::PNMReader->new;
$pnm1->SetFileName("$VTK_DATA/fran_cut.ppm");
$atext = Graphics::VTK::Texture->new;
$atext->SetInput($pnm1->GetOutput);
$atext->InterpolateOn;
$cyberActor = Graphics::VTK::Actor->new;
$cyberActor->SetMapper($cyberMapper);
$cyberActor->SetTexture($atext);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($cyberActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$ren1->GetActiveCamera->Azimuth(90);
$iren->Initialize;
#renWin SetFileName "franFace.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
