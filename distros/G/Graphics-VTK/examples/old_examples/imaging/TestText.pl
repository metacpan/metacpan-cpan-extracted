#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# demonstrate the use of 2D text
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
$sphere = Graphics::VTK::SphereSource->new;
$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($sphere->GetOutput);
$sphereMapper->GlobalImmediateModeRenderingOn;
$sphereActor = Graphics::VTK::LODActor->new;
$sphereActor->SetMapper($sphereMapper);
$textMapper = Graphics::VTK::TextMapper->new;
$textMapper->SetInput("This is a sphere");
$textMapper->SetFontSize(18);
$textMapper->SetFontFamilyToArial;
$textMapper->SetJustificationToCentered;
$textMapper->BoldOn;
$textMapper->ItalicOn;
$textMapper->ShadowOn;
$textActor = Graphics::VTK::ScaledTextActor->new;
$textActor->SetMapper($textMapper);
$textActor->GetProperty->SetColor(0,0,1);
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor2D($textActor);
$ren1->AddActor($sphereActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(250,125);
$ren1->GetActiveCamera->Zoom(1.5);
$renWin->Render;
#renWin SetFileName "TestText.tcl.ppm"
#renWin SaveImageAsPPM
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
