#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Example demonstrates generating scalars based on elevation.
use Graphics::VTK::Tk::vtkInt;
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetPhiResolution(12);
$sphere->SetThetaResolution(12);
$colorIt = Graphics::VTK::SimpleElevationFilter->new;
$colorIt->SetInput($sphere->GetOutput);
$colorIt->SetVector(0,1,0);
#do this to get better coverage :)
$colorIt->SetVector(0,0,1);
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($colorIt->GetPolyDataOutput);
$mapper->SetScalarRange(-1,1);
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($actor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(400,400);
$ren1->GetActiveCamera->Zoom(1.4);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$renWin->SetFileName('simpleElevation.tcl.ppm');
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
