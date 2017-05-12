#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInt;
$sphere1 = Graphics::VTK::SphereSource->new;
$sphere1->SetPhiResolution(0);
$sphere1->SetThetaResolution(0);
$sphere1->SetStartPhi(0);
$sphere1->SetEndPhi(90);
$sphere2 = Graphics::VTK::SphereSource->new;
$sphere2->SetPhiResolution(0);
$sphere2->SetThetaResolution(0);
$sphere2->SetStartPhi(90);
$sphere2->SetEndPhi(180);
$mapper1 = Graphics::VTK::PolyDataMapper->new;
$mapper1->SetInput($sphere1->GetOutput);
$actor1 = Graphics::VTK::Actor->new;
$actor1->SetMapper($mapper1);
$mapper2 = Graphics::VTK::PolyDataMapper->new;
$mapper2->SetInput($sphere2->GetOutput);
$actor2 = Graphics::VTK::Actor->new;
$actor2->SetMapper($mapper2);
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($actor1);
$ren1->AddActor($actor2);
$ren1->SetBackground(1,1,1);
$ren1->GetActiveCamera->Elevation(90);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$renWin->SetFileName('matchingSpheres.tcl.ppm');
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
