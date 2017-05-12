#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version to decimtae fran's face
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
#7347 triangles remain
$deci = Graphics::VTK::Decimate->new;
$deci->SetInput($cyber->GetOutput);
$deci->SetTargetReduction(0.9);
$deci->SetAspectRatio(20);
$deci->SetInitialError(0.0002);
$deci->SetErrorIncrement(0.0005);
$deci->SetMaximumIterations(6);
$smooth = Graphics::VTK::SmoothPolyDataFilter->new;
$smooth->SetInput($deci->GetOutput);
$smooth->SetNumberOfIterations(50);
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($smooth->GetOutput);
$cyberMapper = Graphics::VTK::PolyDataMapper->new;
$cyberMapper->SetInput($normals->GetOutput);
$cyberActor = Graphics::VTK::Actor->new;
$cyberActor->SetMapper($cyberMapper);
$cyberActor->GetProperty->SetColor(1.0,0.49,0.25);
$cyberActor->GetProperty->SetRepresentationToWireframe;
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
$cam1 = Graphics::VTK::Camera->new;
$cam1->SetClippingRange(0.0475572,2.37786);
$cam1->SetFocalPoint(0.052665,-0.129454,-0.0573973);
$cam1->SetPosition(0.327637,-0.116299,-0.256418);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(-0.0225386,0.999137,0.034901);
$ren1->SetActiveCamera($cam1);
$iren->Initialize;
$renWin->SetFileName("valid/smoothFran.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
