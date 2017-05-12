#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Manipulate/test vtkSphereSource
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# create pipeline
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetRadius(1);
$sphere2 = Graphics::VTK::SphereSource->new;
$sphere2->SetCenter(2.5,0,0);
$sphere2->SetRadius(1);
$sphere2->SetStartTheta(90);
$sphere2->SetEndTheta(270);
$sphere3 = Graphics::VTK::SphereSource->new;
$sphere3->SetCenter(0,2.5,0);
$sphere3->SetRadius(1);
$sphere3->SetStartPhi(90);
$sphere3->SetEndPhi(135);
$sphere4 = Graphics::VTK::SphereSource->new;
$sphere4->SetCenter(2.5,2.5,0);
$sphere4->SetRadius(1);
$sphere4->SetEndTheta(180);
$sphere4->SetStartPhi(90);
$sphere4->SetEndPhi(135);
$appendSpheres = Graphics::VTK::AppendPolyData->new;
$appendSpheres->AddInput($sphere->GetOutput);
$appendSpheres->AddInput($sphere2->GetOutput);
$appendSpheres->AddInput($sphere3->GetOutput);
$appendSpheres->AddInput($sphere4->GetOutput);
$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($appendSpheres->GetOutput);
$sphereMapper->ScalarVisibilityOff;
$sphereActor = Graphics::VTK::Actor->new;
$sphereActor->SetMapper($sphereMapper);
$sphereActor->GetProperty->SetColor(@Graphics::VTK::Colors::peacock);
# Create renderer stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($sphereActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$iren->Initialize;
$renWin->Render;
$ren1->GetActiveCamera->Zoom(1.5);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
#renWin SetFileName "sphere.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
