#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# include get the vtk interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$cone = Graphics::VTK::ConeSource->new;
$cone->SetResolution(6);
$cone->CappingOff;
$clean = Graphics::VTK::CleanPolyData->new;
$clean->SetInput($cone->GetOutput);
$clean->SetTolerance('.1');
$subdivide = Graphics::VTK::ButterflySubdivisionFilter->new;
$subdivide->SetInput($clean->GetOutput);
$subdivide->SetNumberOfSubdivisions(5);
$mapper = Graphics::VTK::DataSetMapper->new;
$mapper->SetInput($subdivide->GetOutput);
$anActor = Graphics::VTK::Actor->new;
$anActor->SetMapper($mapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($anActor);
$back = Graphics::VTK::Property->new;
$back->SetDiffuseColor(0.8900,0.8100,0.3400);
$anActor->SetBackfaceProperty($back);
$anActor->GetProperty->SetDiffuseColor(1,'.4','.3');
$anActor->GetProperty->SetSpecular('.4');
$anActor->GetProperty->SetDiffuse('.8');
$anActor->GetProperty->SetSpecularPower(40);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(300,300);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$cam1 = $ren1->GetActiveCamera;
$ren1->GetActiveCamera->SetPosition(-1.54037,-2.66027,-0.66041);
$ren1->GetActiveCamera->SetFocalPoint(-0.231198,0.0987853,0.0350584);
$ren1->GetActiveCamera->SetViewAngle(21.4286);
$ren1->GetActiveCamera->SetViewUp(0.566532,-0.0616892,-0.821728);
$ren1->GetActiveCamera->SetViewPlaneNormal(-0.417987,-0.880899,-0.222046);
$ren1->ResetCameraClippingRange;
$iren->Initialize;
$renWin->SetFileName("subdivideCone.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
