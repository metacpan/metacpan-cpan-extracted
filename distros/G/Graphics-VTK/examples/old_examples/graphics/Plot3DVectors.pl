#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# All Plot3D vector functions
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$renWin = Graphics::VTK::RenderWindow->new;
$ren1 = Graphics::VTK::Renderer->new;
$ren1->SetBackground('.8','.8','.2');
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
@vectorLabels = qw/Velocity Vorticity Momentum Pressure_Gradient/;
@vectorFunctions = qw/200 201 202 210/;
$camera = Graphics::VTK::Camera->new;
$light = Graphics::VTK::Light->new;
$i = 0;
foreach $vectorFunction (@vectorFunctions)
 {
  $pl3d{$vectorFunction} = Graphics::VTK::PLOT3DReader->new;
  $pl3d{$vectorFunction}->SetXYZFileName("$VTK_DATA/bluntfinxyz.bin");
  $pl3d{$vectorFunction}->SetQFileName("$VTK_DATA/bluntfinq.bin");
  $pl3d{$vectorFunction}->SetVectorFunctionNumber($vectorFunction);
  $pl3d{$vectorFunction}->Update;
  $plane{$vectorFunction} = Graphics::VTK::StructuredGridGeometryFilter->new;
  $plane{$vectorFunction}->SetInput($pl3d{$vectorFunction}->GetOutput);
  $plane{$vectorFunction}->SetExtent(25,25,0,100,0,100);
  $hog{$vectorFunction} = Graphics::VTK::HedgeHog->new;
  $hog{$vectorFunction}->SetInput($plane{$vectorFunction}->GetOutput);
  $hog{$vectorFunction}->SetScaleFactor(1.0 / $pl3d{$vectorFunction}->GetOutput->GetPointData->GetVectors->GetMaxNorm);
  $mapper{$vectorFunction} = Graphics::VTK::PolyDataMapper->new;
  $mapper{$vectorFunction}->SetInput($hog{$vectorFunction}->GetOutput);
  $actor{$vectorFunction} = Graphics::VTK::Actor->new;
  $actor{$vectorFunction}->SetMapper($mapper{$vectorFunction});
  $ren{$vectorFunction} = Graphics::VTK::Renderer->new;
  $ren{$vectorFunction}->SetBackground(0.5,'.5','.5');
  $ren{$vectorFunction}->SetActiveCamera($camera);
  $ren{$vectorFunction}->AddLight($light);
  $renWin->AddRenderer($ren{$vectorFunction});
  $ren{$vectorFunction}->AddActor($actor{$vectorFunction});
  $textMapper{$vectorFunction} = Graphics::VTK::TextMapper->new;
  $textMapper{$vectorFunction}->SetInput($vectorLabels[$i]);
  $textMapper{$vectorFunction}->SetFontSize(10);
  $textMapper{$vectorFunction}->SetFontFamilyToArial;
  $text{$vectorFunction} = Graphics::VTK::Actor2D->new;
  $text{$vectorFunction}->SetMapper($textMapper{$vectorFunction});
  $text{$vectorFunction}->SetPosition(2,5);
  $text{$vectorFunction}->GetProperty->SetColor('.3',1,1);
  $ren{$vectorFunction}->AddActor2D($text{$vectorFunction});
  $i += 1;
 }
# now layout renderers
$column = 1;
$row = 1;
$deltaX = 1.0 / 2.0;
$deltaY = 1.0 / 2.0;
foreach $vectorFunction (@vectorFunctions)
 {
  $ren{$vectorFunction}->SetViewport(($column - 1) * $deltaX + ($deltaX * '.05'),($row - 1) * $deltaY + ($deltaY * '.05'),$column * $deltaX - ($deltaX * '.05'),$row * $deltaY - ($deltaY * '.05'));
  $column += 1;
  if ($column > 2)
   {
    $column = 1;
    $row += 1;
   }
 }
$camera->SetViewUp(1,0,0);
$camera->SetFocalPoint(0,0,0);
$camera->SetPosition('.4','-.5','-.75');
$camera->ComputeViewPlaneNormal;
$ren{200}->ResetCamera;
$camera->Dolly(1.25);
$ren{200}->ResetCameraClippingRange;
$ren{201}->ResetCameraClippingRange;
$ren{202}->ResetCameraClippingRange;
$ren{210}->ResetCameraClippingRange;
$light->SetPosition($camera->GetPosition);
$light->SetFocalPoint($camera->GetFocalPoint);
$renWin->SetSize(350,350);
$renWin->Render;
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->SetFileName("Plot3DVectors.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
