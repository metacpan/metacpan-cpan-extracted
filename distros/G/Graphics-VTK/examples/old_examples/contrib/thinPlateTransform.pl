#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# Test the vtkThinPlateSplineTransform class
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version of the Mace example
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# create a sphere source and actor
$original = Graphics::VTK::SphereSource->new;
$original->SetThetaResolution(100);
$original->SetPhiResolution(100);
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($original->GetOutput);
$spoints = Graphics::VTK::Points->new;
$spoints->SetNumberOfPoints(6);
$tpoints = Graphics::VTK::Points->new;
$tpoints->SetNumberOfPoints(6);
$spoints->SetPoint(0,0,0,0);
$tpoints->SetPoint(0,0,0,0);
$spoints->SetPoint(1,1,0,0);
$tpoints->SetPoint(1,1,0,0);
$spoints->SetPoint(2,0,1,0);
$tpoints->SetPoint(2,0,1,0);
$spoints->SetPoint(3,1,1,1);
$tpoints->SetPoint(3,1,1,0.5);
$spoints->SetPoint(4,-1,1,2);
$tpoints->SetPoint(4,-1,1,3);
$spoints->SetPoint(5,0.5,0.5,2);
$tpoints->SetPoint(5,0.5,0.5,1);
$trans = Graphics::VTK::ThinPlateSplineTransform->new;
$trans->SetSourceLandmarks($spoints);
$trans->SetTargetLandmarks($tpoints);
# yeah, this is silly -- improves code coverage though
$transconcat = Graphics::VTK::GeneralTransformConcatenation->new;
$transconcat->Concatenate($trans);
$transconcat->Concatenate($trans->GetInverse);
$transconcat->Concatenate($trans);
$warp = Graphics::VTK::TransformPolyDataFilter->new;
$warp->SetInput($original->GetOutput);
$warp->SetTransform($transconcat);
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($warp->GetOutput);
$backProp = Graphics::VTK::Property->new;
$backProp->SetDiffuseColor(@Graphics::VTK::Colors::tomato);
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
$actor->GetProperty->SetColor(@Graphics::VTK::Colors::peacock);
$actor->SetBackfaceProperty($backProp);
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->SetSize(100,250);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($actor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(200,300);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(1.87,3.9);
$cam1->SetFocalPoint(0,0,0.254605);
$cam1->SetPosition(0.571764,2.8232,0.537528);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(0.5188,-0.0194195,-0.854674);
$renWin->Render;
$renWin->SetFileName("thinPlateTransform.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
