#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this demonstrates use of assemblies
# include get the vtk interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create four parts: a top level assembly and three primitives
$sphere = Graphics::VTK::SphereSource->new;
$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($sphere->GetOutput);
$sphereActor = Graphics::VTK::Actor->new;
$sphereActor->SetMapper($sphereMapper);
$sphereActor->SetOrigin(2,1,3);
$sphereActor->RotateY(6);
$sphereActor->SetPosition(2.25,0,0);
$sphereActor->GetProperty->SetColor(1,0,1);
$cube = Graphics::VTK::CubeSource->new;
$cubeMapper = Graphics::VTK::PolyDataMapper->new;
$cubeMapper->SetInput($cube->GetOutput);
$cubeActor = Graphics::VTK::Actor->new;
$cubeActor->SetMapper($cubeMapper);
$cubeActor->SetPosition(0.0,'.25',0);
$cubeActor->GetProperty->SetColor(0,0,1);
$cone = Graphics::VTK::ConeSource->new;
$coneMapper = Graphics::VTK::PolyDataMapper->new;
$coneMapper->SetInput($cone->GetOutput);
$coneActor = Graphics::VTK::Actor->new;
$coneActor->SetMapper($coneMapper);
$coneActor->SetPosition(0,0,'.25');
$coneActor->GetProperty->SetColor(0,1,0);
$cylinder = Graphics::VTK::CylinderSource->new;
#top part
$cylinderMapper = Graphics::VTK::PolyDataMapper->new;
$cylinderMapper->SetInput($cylinder->GetOutput);
$cylinderActor = Graphics::VTK::Assembly->new;
$cylinderActor->SetMapper($cylinderMapper);
$cylinderActor->AddPart($sphereActor);
$cylinderActor->AddPart($cubeActor);
$cylinderActor->AddPart($coneActor);
$cylinderActor->SetOrigin(5,10,15);
$cylinderActor->AddPosition(5,0,0);
$cylinderActor->RotateX(15);
$cylinderActor->GetProperty->SetColor(1,0,0);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($cylinderActor);
$ren1->AddActor($coneActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(450,450);
# Get handles to some useful objects
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$renWin->Render;
#renWin SetFileName assembly.tcl.ppm
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
