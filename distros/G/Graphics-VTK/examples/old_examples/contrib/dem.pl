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
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$Scale = 5;
$lut = Graphics::VTK::LookupTable->new;
$lut->SetHueRange(0.6,0);
$lut->SetSaturationRange(1.0,0);
$lut->SetValueRange(0.5,1.0);
$demModel = Graphics::VTK::DEMReader->new;
$demModel->SetFileName("$VTK_DATA/albany-w");
$demModel->Update;
$demModel->Print;
$lo = $Scale * ($demModel->GetElevationBounds)[0];
$hi = $Scale * ($demModel->GetElevationBounds)[1];
$demActor = Graphics::VTK::LODActor->new;
# create a pipeline for each lod mapper
$lods = '4 8 16';
foreach $lod ($lods)
 {
  $shrink{$lod} = Graphics::VTK::ImageShrink3D->new;
  $shrink{$lod}->SetShrinkFactors($lod,$lod,1);
  $shrink{$lod}->SetInput($demModel->GetOutput);
  $shrink{$lod}->AveragingOn;
  $geom{$lod} = Graphics::VTK::StructuredPointsGeometryFilter->new;
  $geom{$lod}->SetInput($shrink{$lod}->GetOutput);
  $geom{$lod}->ReleaseDataFlagOn;
  $warp{$lod} = Graphics::VTK::WarpScalar->new;
  $warp{$lod}->SetInput($geom{$lod}->GetOutput);
  $warp{$lod}->SetNormal(0,0,1);
  $warp{$lod}->UseNormalOn;
  $warp{$lod}->SetScaleFactor($Scale);
  $warp{$lod}->ReleaseDataFlagOn;
  $elevation{$lod} = Graphics::VTK::ElevationFilter->new;
  $elevation{$lod}->SetInput($warp{$lod}->GetOutput);
  $elevation{$lod}->SetLowPoint(0,0,$lo);
  $elevation{$lod}->SetHighPoint(0,0,$hi);
  $elevation{$lod}->SetScalarRange($lo,$hi);
  $elevation{$lod}->ReleaseDataFlagOn;
  $toPoly{$lod} = Graphics::VTK::CastToConcrete->new;
  $toPoly{$lod}->SetInput($elevation{$lod}->GetOutput);
  $normals{$lod} = Graphics::VTK::PolyDataNormals->new;
  $normals{$lod}->SetInput($toPoly{$lod}->GetPolyDataOutput);
  $normals{$lod}->SetMaxRecursionDepth(1000);
  $normals{$lod}->SetFeatureAngle(60);
  $normals{$lod}->ConsistencyOff;
  $normals{$lod}->SplittingOff;
  $normals{$lod}->ReleaseDataFlagOn;
  $demMapper{$lod} = Graphics::VTK::PolyDataMapper->new;
  $demMapper{$lod}->SetInput($normals{$lod}->GetOutput);
  $demMapper{$lod}->SetScalarRange($lo,$hi);
  $demMapper{$lod}->SetLookupTable($lut);
  $demMapper{$lod}->ImmediateModeRenderingOn;
  $demMapper{$lod}->Update;
  $demActor->AddLODMapper($demMapper{$lod});
 }
# Add the actors to the renderer, set the background and size
$ren1->AddActor($demActor);
$ren1->SetBackground('.4','.4','.4');
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->SetDesiredUpdateRate(1);
$MW->withdraw;
#
sub TkCheckAbort
{
 my $foo;
 $foo = $renWin->GetEventPending;
 $renWin->SetAbortRender(1) if ($foo != 0);
}
$renWin->SetAbortCheckMethod(
 sub
  {
   TkCheckAbort();
  }
);
$ren1->GetActiveCamera->SetViewUp(0,0,1);
$ren1->GetActiveCamera->SetPosition(-99900,-21354,131801);
$ren1->GetActiveCamera->SetFocalPoint(41461,41461,2815);
$ren1->GetActiveCamera->ComputeViewPlaneNormal;
$ren1->ResetCamera;
$ren1->GetActiveCamera->Dolly(1.2);
$ren1->ResetCameraClippingRange;
$renWin->Render;
$renWin->SetFileName('dem.tcl.ppm');
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
