#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# splat points to generate surface
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# read cyberware file
$cyber = Graphics::VTK::PolyDataReader->new;
$cyber->SetFileName("$VTK_DATA/fran_cut.vtk");
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($cyber->GetOutput);
$normals->SetMaxRecursionDepth(100);
$mask = Graphics::VTK::MaskPoints->new;
$mask->SetInput($normals->GetOutput);
$mask->SetOnRatio(50);
#    mask RandomModeOn
$splatter = Graphics::VTK::GaussianSplatter->new;
$splatter->SetInput($mask->GetOutput);
$splatter->SetSampleDimensions(100,100,100);
$splatter->SetEccentricity(2.5);
$splatter->NormalWarpingOn;
$splatter->SetScaleFactor(1.0);
$splatter->SetRadius(0.025);
$contour = Graphics::VTK::ContourFilter->new;
$contour->SetInput($splatter->GetOutput);
$contour->SetValue(0,0.25);
$splatMapper = Graphics::VTK::PolyDataMapper->new;
$splatMapper->SetInput($contour->GetOutput);
$splatMapper->ScalarVisibilityOff;
$splatActor = Graphics::VTK::Actor->new;
$splatActor->SetMapper($splatMapper);
$splatActor->GetProperty->SetColor(1.0,0.49,0.25);
$cyberMapper = Graphics::VTK::PolyDataMapper->new;
$cyberMapper->SetInput($cyber->GetOutput);
$cyberMapper->ScalarVisibilityOff;
$cyberActor = Graphics::VTK::Actor->new;
$cyberActor->SetMapper($cyberMapper);
$cyberActor->GetProperty->SetRepresentationToWireframe;
$cyberActor->GetProperty->SetColor(0.2510,0.8784,0.8157);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($cyberActor);
$ren1->AddActor($splatActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$ren1->SetBackground(1,1,1);
$camera = Graphics::VTK::Camera->new;
$camera->SetClippingRange(0.0332682,1.66341);
$camera->SetFocalPoint(0.0511519,-0.127555,-0.0554379);
$camera->SetPosition(0.516567,-0.124763,-0.349538);
$camera->ComputeViewPlaneNormal;
$camera->SetViewAngle(18.1279);
$camera->SetViewUp(-0.013125,0.99985,-0.0112779);
$ren1->SetActiveCamera($camera);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
#renWin SetFileName "splatFace.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
