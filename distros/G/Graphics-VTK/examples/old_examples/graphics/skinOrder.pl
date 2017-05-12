#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this test is the same as graphics/examplesTcl/skinOrder.tcl
# except that is uses vtkVolume16Reader, not vtkImageReader
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
#source $VTK_TCL/frog/SliceOrder.tcl
# Create the RenderWindow, Renderer and Interactor
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$RESOLUTION = 64;
$START_SLICE = 1;
$END_SLICE = 93;
$PIXEL_SIZE = 3.2;
$centerX = ($RESOLUTION / 2);
$centerY = ($RESOLUTION / 2);
$centerZ = ($END_SLICE - $START_SLICE) / 2;
$endX = ($RESOLUTION - 1);
$endY = ($RESOLUTION - 1);
$endZ = ($END_SLICE - 1);
$origin = ($RESOLUTION / 2.0) * $PIXEL_SIZE * -1.0;
$math = Graphics::VTK::Math->new;
$orders = "ap pa si is lr rl";
foreach $order ($orders)
 {
  $reader{$order} = Graphics::VTK::Volume16Reader->new;
  $reader{$order}->SetDataDimensions($RESOLUTION,$RESOLUTION);
  $reader{$order}->SetFilePrefix("$VTK_DATA/headsq/quarter");
  $reader{$order}->SetDataSpacing($PIXEL_SIZE,$PIXEL_SIZE,1.5);
  $reader{$order}->SetDataOrigin($origin,$origin,1.5);
  $reader{$order}->SetImageRange($START_SLICE,$END_SLICE);
  $reader{$order}->SetTransform($order);
  $reader{$order}->SetHeaderSize(0);
  $reader{$order}->SetDataMask(0x7fff);
  $reader{$order}->SetDataByteOrderToLittleEndian;
  $reader{$order}->GetOutput->ReleaseDataFlagOn;
  $iso{$order} = Graphics::VTK::ContourFilter->new;
  $iso{$order}->SetInput($reader{$order}->GetOutput);
  $iso{$order}->SetValue(0,550.5);
  $iso{$order}->ComputeScalarsOff;
  $iso{$order}->ReleaseDataFlagOn;
  $mapper{$order} = Graphics::VTK::PolyDataMapper->new;
  $mapper{$order}->SetInput($iso{$order}->GetOutput);
  $mapper{$order}->ImmediateModeRenderingOn;
  $actor{$order} = Graphics::VTK::Actor->new;
  $actor{$order}->SetMapper($mapper{$order});
  $actor{$order}->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::math->Random('.5',1),$math->Random('.5',1),$math->Random('.5',1));
  $ren1->AddActor($actor{$order});
 }
$renWin->SetSize(300,300);
$ren1->GetActiveCamera->Azimuth(210);
$ren1->GetActiveCamera->Elevation(30);
$ren1->GetActiveCamera->Dolly(1.2);
$ren1->ResetCameraClippingRange;
$ren1->SetBackground('.8','.8','.8');
$iren->Initialize;
$renWin->Render;
#renWin SetFileName "skinOrder.tcl.ppm"
#renWin SaveImageAsPPM
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
