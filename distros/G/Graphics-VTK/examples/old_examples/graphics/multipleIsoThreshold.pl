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
## Graphics stuff
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA/combxyz.bin");
$pl3d->SetQFileName("$VTK_DATA/combq.bin");
$pl3d->SetScalarFunctionNumber(100);
$pl3d->SetVectorFunctionNumber(202);
$pl3d->Update;
$range = $pl3d->GetOutput->GetPointData->GetScalars->GetRange;
$min = $range[0];
$max = $range[1];
$value = ($min + $max) / 2.0;
$numberOfContours = 5;
$epsilon = ($max - $min) / ($numberOfContours * 10);
$min = $min + $epsilon;
$max = $max - $epsilon;
$cf = Graphics::VTK::ContourFilter->new;
$cf->SetInput($pl3d->GetOutput);
$cf->GenerateValues($numberOfContours,$min,$max);
$cf->UseScalarTreeOn;
for ($i = 1; $i <= $numberOfContours; $i += 1)
 {
  $threshold{$i} = Graphics::VTK::Threshold->new;
  $threshold{$i}->SetInput($cf->GetOutput);
  $value = $min + ($i - 1) * ($max - $min) / ($numberOfContours - 1);
  $threshold{$i}->ThresholdBetween($value - $epsilon,$value + $epsilon);
  $mapper{$i} = Graphics::VTK::DataSetMapper->new;
  $mapper{$i}->SetInput($threshold{$i}->GetOutput);
  $mapper{$i}->SetScalarRange($pl3d->GetOutput->GetPointData->GetScalars->GetRange);
  $actor{$i} = Graphics::VTK::Actor->new;
  $actor{$i}->AddPosition(0,$i * 12,0);
  $actor{$i}->SetMapper($mapper{$i});
  $ren1->AddActor($actor{$i});
 }
# Add the actors to the renderer, set the background and size
$ren1->SetBackground('.3','.3','.3');
$renWin->SetSize(600,200);
$cam1 = $ren1->GetActiveCamera;
$ren1->GetActiveCamera->SetPosition(-36.3762,32.3855,51.3652);
$ren1->GetActiveCamera->SetFocalPoint(8.255,33.3861,29.7687);
$ren1->GetActiveCamera->SetViewAngle(30);
$ren1->GetActiveCamera->SetViewUp(0,0,1);
$ren1->GetActiveCamera->ComputeViewPlaneNormal;
$ren1->ResetCameraClippingRange;
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
#renWin SetFileName multipleIsoThreshold.tcl.ppm
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
