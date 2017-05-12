#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$ren2 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->AddRenderer($ren2);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create pipeline for ren1
$pl3d2 = Graphics::VTK::PLOT3DReader->new;
$pl3d2->SetXYZFileName("$VTK_DATA/combxyz.bin");
$pl3d2->SetQFileName("$VTK_DATA/combq.bin");
$pl3d2->SetScalarFunctionNumber(153);
$pl3d2->Update;
$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA/combxyz.bin");
$pl3d->SetQFileName("$VTK_DATA/combq.bin");
$pl3d->SetScalarFunctionNumber(120);
$pl3d->SetVectorFunctionNumber(202);
$pl3d->Update;
$iso = Graphics::VTK::ContourFilter->new;
$iso->SetInput($pl3d->GetOutput);
$iso->SetValue(0,-100000);
$probe2 = Graphics::VTK::ProbeFilter->new;
$probe2->SetInput($iso->GetOutput);
$probe2->SetSource($pl3d2->GetOutput);
$cast2 = Graphics::VTK::CastToConcrete->new;
$cast2->SetInput($probe2->GetOutput);
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetMaxRecursionDepth(100);
$normals->SetInput($cast2->GetPolyDataOutput);
$normals->SetFeatureAngle(45);
$isoMapper = Graphics::VTK::PolyDataMapper->new;
$isoMapper->SetInput($normals->GetOutput);
$isoMapper->ScalarVisibilityOn;
$isoMapper->SetScalarRange($pl3d2->GetOutput->GetPointData->GetScalars->GetRange);
$isoActor = Graphics::VTK::Actor->new;
$isoActor->SetMapper($isoMapper);
$isoActor->GetProperty->SetColor(@Graphics::VTK::Colors::bisque);
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($isoActor);
$ren1->SetBackground(1,1,1);
$ren1->SetViewport(0,0,'.5',1);
$renWin->SetSize(512,256);
$ren1->SetBackground(0.1,0.2,0.4);
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(3.95297,50);
$cam1->SetFocalPoint(9.71821,0.458166,29.3999);
$cam1->SetPosition(2.7439,-37.3196,38.7167);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(-0.16123,0.264271,0.950876);
$aPlane = Graphics::VTK::PlaneSource->new;
$aPlaneMapper = Graphics::VTK::PolyDataMapper->new;
$aPlaneMapper->SetInput($aPlane->GetOutput);
$aPlaneMapper->ImmediateModeRenderingOn;
$screen = Graphics::VTK::Actor->new;
$screen->SetMapper($aPlaneMapper);
$ren2->AddActor($screen);
$ren2->SetViewport('.5',0,1,1);
$ren2->GetActiveCamera->Azimuth(30);
$ren2->GetActiveCamera->Elevation(30);
$ren2->SetBackground('.8','.4','.3');
$ren1->ResetCameraClippingRange;
$ren2->ResetCameraClippingRange;
$renWin->Render;
$ren1Image = Graphics::VTK::RendererSource->new;
$ren1Image->SetInput($ren1);
$ren1Image->DepthValuesOn;
$aTexture = Graphics::VTK::Texture->new;
$aTexture->SetInput($ren1Image->GetOutput);
$screen->SetTexture($aTexture);
$renWin->Render;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
#renWin SetFileName "rendererSource.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
