#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version of old strip unstructured data
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
$deci = Graphics::VTK::Decimate->new;
$deci->SetInput($cyber->GetOutput);
$deci->SetTargetReduction(0.90);
$deci->SetInitialError(0.0002);
$deci->SetErrorIncrement(0.0004);
$deci->SetMaximumIterations(6);
$deci->SetInitialFeatureAngle(45);
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($deci->GetOutput);
$mask = Graphics::VTK::MaskPolyData->new;
$mask->SetInput($normals->GetOutput);
$mask->SetOnRatio(2);
$cyberMapper = Graphics::VTK::PolyDataMapper->new;
$cyberMapper->SetInput($mask->GetOutput);
$cyberActor = Graphics::VTK::Actor->new;
$cyberActor->SetMapper($cyberMapper);
$cyberActor->GetProperty->SetColor(1.0,0.49,0.25);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($cyberActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
# render the image
$cam1 = Graphics::VTK::Camera->new;
$cam1->SetFocalPoint(0.0520703,-0.128547,-0.0581083);
$cam1->SetPosition(0.419653,-0.120916,-0.321626);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewAngle(21.4286);
$cam1->SetViewUp(-0.0136986,0.999858,0.00984497);
$ren1->SetActiveCamera($cam1);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
#renWin SetFileName "uStripeF.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
