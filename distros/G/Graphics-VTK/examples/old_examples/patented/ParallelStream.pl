#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example test the ParallelStreaming flag in the 
# vtkAppendPolyData filter.
# parameters
$NUMBER_OF_PIECES = 13;
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,127,0,127,1,93);
$reader->SetFilePrefix("$VTK_DATA/headsq/half");
$reader->SetDataSpacing(1.6,1.6,1.5);
$app = Graphics::VTK::AppendPolyData->new;
$app->ParallelStreamingOn;
for ($i = 0; $i < $NUMBER_OF_PIECES; $i += 1)
 {
  #  vtkContourFilter iso$i
  $iso{$i} = Graphics::VTK::SynchronizedTemplates3D->new;
  $iso{$i}->SetInput($reader->GetOutput);
  $iso{$i}->SetValue(0,500);
  $iso{$i}->ComputeScalarsOff;
  $iso{$i}->ComputeGradientsOff;
  $iso{$i}->SetNumberOfThreads(1);
  if ($NUMBER_OF_PIECES == 1)
   {
    $val = 0.0;
   }
  else
   {
    $val = 0.0 + $i / ($NUMBER_OF_PIECES - 1.0);
   }
  $elev{$i} = Graphics::VTK::ElevationFilter->new;
  $elev{$i}->SetInput($iso{$i}->GetOutput);
  $elev{$i}->SetScalarRange($val,$val + 0.001);
  $app->AddInput($elev{$i}->GetOutput);
 }
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($app->GetOutput);
$mapper->ImmediateModeRenderingOn;
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
$actor->GetProperty->SetSpecularPower(30);
$actor->GetProperty->SetDiffuse('.7');
$actor->GetProperty->SetSpecular('.5');
$ren1->AddActor($actor);
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($reader->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->VisibilityOff;
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->SetBackground(0.9,'.9','.9');
$ren1->GetActiveCamera->SetFocalPoint(100,100,65);
$ren1->GetActiveCamera->SetPosition(100,450,65);
$ren1->GetActiveCamera->SetViewUp(0,0,-1);
$ren1->GetActiveCamera->SetViewAngle(30);
$ren1->GetActiveCamera->ComputeViewPlaneNormal;
$ren1->ResetCameraClippingRange;
$renWin->SetSize(450,450);
$iren->Initialize;
# render the image
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
