#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this demonstrates assemblies hierarchies
# include get the vtk interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$sphere = Graphics::VTK::SphereSource->new;
$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($sphere->GetOutput);
$sphereActor = Graphics::VTK::Actor->new;
$sphereActor->SetMapper($sphereMapper);
$sphereActor->SetOrigin(2,1,3);
$sphereActor->RotateY(6);
$sphereActor->SetPosition(2.25,0,0);
$sphereActor->GetProperty->SetColor(1,1,0);
$cube = Graphics::VTK::CubeSource->new;
$cubeMapper = Graphics::VTK::PolyDataMapper->new;
$cubeMapper->SetInput($cube->GetOutput);
$cubeActor = Graphics::VTK::Actor->new;
$cubeActor->SetMapper($cubeMapper);
$cubeActor->SetPosition(0.0,'.25',0);
$cubeActor->GetProperty->SetColor(0,1,1);
$cone = Graphics::VTK::ConeSource->new;
$coneMapper = Graphics::VTK::PolyDataMapper->new;
$coneMapper->SetInput($cone->GetOutput);
$coneActor = Graphics::VTK::Actor->new;
$coneActor->SetMapper($coneMapper);
$coneActor->SetPosition(0,0,'.25');
$coneActor->GetProperty->SetColor(1,0,1);
$cylinder = Graphics::VTK::CylinderSource->new;
#top part
$cylinderMapper = Graphics::VTK::PolyDataMapper->new;
$cylinderMapper->SetInput($cylinder->GetOutput);
$cylActor = Graphics::VTK::Actor->new;
$cylActor->SetMapper($cylinderMapper);
$cylinderActor = Graphics::VTK::Assembly->new;
$cylinderActor->SetMapper($cylinderMapper);
$cylinderActor->AddPart($sphereActor);
$cylinderActor->AddPart($cubeActor);
$cylinderActor->AddPart($coneActor);
$cylinderActor->SetOrigin(5,10,15);
$cylinderActor->AddPosition(5,0,0);
$cylinderActor->RotateX(45);
$cylinderActor->GetProperty->SetColor(1,0,0);
$cylinderActor2 = Graphics::VTK::Assembly->new;
$cylinderActor2->SetMapper($cylinderMapper);
$cylinderActor2->AddPart($sphereActor);
$cylinderActor2->AddPart($cubeActor);
$cylinderActor2->AddPart($coneActor);
$cylinderActor2->SetOrigin(5,10,15);
$cylinderActor2->AddPosition(6,0,0);
$cylinderActor2->RotateX(50);
$cylinderActor2->GetProperty->SetColor(0,1,0);
$twoGroups = Graphics::VTK::Assembly->new;
$twoGroups->AddPart($cylinderActor);
$twoGroups->AddPart($cylinderActor2);
$twoGroups->AddPosition(0,0,2);
$twoGroups->RotateX(15);
$twoGroups2 = Graphics::VTK::Assembly->new;
$twoGroups2->AddPart($cylinderActor);
$twoGroups2->AddPart($cylinderActor2);
$twoGroups2->AddPosition(3,0,0);
$twoGroups3 = Graphics::VTK::Assembly->new;
$twoGroups3->AddPart($cylinderActor);
$twoGroups3->AddPart($cylinderActor2);
$twoGroups3->AddPosition(0,4,0);
$threeGroups = Graphics::VTK::Assembly->new;
$threeGroups->AddPart($twoGroups);
$threeGroups->AddPart($twoGroups2);
$threeGroups->AddPart($twoGroups3);
$threeGroups2 = Graphics::VTK::Assembly->new;
$threeGroups2->AddPart($twoGroups);
$threeGroups2->AddPart($twoGroups2);
$threeGroups2->AddPart($twoGroups3);
$threeGroups2->AddPosition(5,5,5);
$topLevel = Graphics::VTK::Assembly->new;
$topLevel->AddPart($threeGroups);
$topLevel->AddPart($threeGroups2);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($threeGroups);
$ren1->AddActor($threeGroups2);
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
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
#renWin SetFileName assembly2.tcl.ppm
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
