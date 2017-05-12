#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# All Plot3D scalar functions
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$renWin = Graphics::VTK::RenderWindow->new;
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
@scalarLabels = qw/Density Pressure Temperature Enthalpy Internal_Energy Kinetic_Energy Velocity_Magnitude Stagnation_Energy Entropy Swirl/;
@scalarFunctions = qw/100 110 120 130 140 144 153 163 170 184/;
$camera = Graphics::VTK::Camera->new;
$light = Graphics::VTK::Light->new;
$math = Graphics::VTK::Math->new;
$i = 0;
foreach $scalarFunction (@scalarFunctions)
 {
  $pl3d{$scalarFunction} = Graphics::VTK::PLOT3DReader->new;
  $pl3d{$scalarFunction}->SetXYZFileName("$VTK_DATA/bluntfinxyz.bin");
  $pl3d{$scalarFunction}->SetQFileName("$VTK_DATA/bluntfinq.bin");
  $pl3d{$scalarFunction}->SetScalarFunctionNumber($scalarFunction);
  $pl3d{$scalarFunction}->Update;
  $plane{$scalarFunction} = Graphics::VTK::StructuredGridGeometryFilter->new;
  $plane{$scalarFunction}->SetInput($pl3d{$scalarFunction}->GetOutput);
  $plane{$scalarFunction}->SetExtent(25,25,0,100,0,100);
  $mapper{$scalarFunction} = Graphics::VTK::PolyDataMapper->new;
  $mapper{$scalarFunction}->SetInput($plane{$scalarFunction}->GetOutput);
  $mapper{$scalarFunction}->SetScalarRange($pl3d{$scalarFunction}->GetOutput->GetPointData->GetScalars->GetRange);
  $actor{$scalarFunction} = Graphics::VTK::Actor->new;
  $actor{$scalarFunction}->SetMapper($mapper{$scalarFunction});
  $ren{$scalarFunction} = Graphics::VTK::Renderer->new;
  $ren{$scalarFunction}->SetBackground(0,0,'.5');
  $ren{$scalarFunction}->SetActiveCamera($camera);
  $ren{$scalarFunction}->AddLight($light);
  $renWin->AddRenderer($ren{$scalarFunction});
  $ren{$scalarFunction}->SetBackground($math->Random('.5',1),$math->Random('.5',1),$math->Random('.5',1));
  $ren{$scalarFunction}->AddActor($actor{$scalarFunction});
  $textMapper{$scalarFunction} = Graphics::VTK::TextMapper->new;
  $textMapper{$scalarFunction}->SetInput($scalarLabels[$i]);
  $textMapper{$scalarFunction}->SetFontSize(10);
  $textMapper{$scalarFunction}->SetFontFamilyToArial;
  $text{$scalarFunction} = Graphics::VTK::Actor2D->new;
  $text{$scalarFunction}->SetMapper($textMapper{$scalarFunction});
  $text{$scalarFunction}->SetPosition(2,3);
  $text{$scalarFunction}->GetProperty->SetColor(0,0,0);
  $ren{$scalarFunction}->AddActor2D($text{$scalarFunction});
  $i += 1;
 }
# now layout renderers
$column = 1;
$row = 1;
$deltaX = 1.0 / 5.0;
$deltaY = 1.0 / 2.0;
foreach $scalarFunction (@scalarFunctions)
 {
  $ren{$scalarFunction}->SetViewport(($column - 1) * $deltaX,($row - 1) * $deltaY,$column * $deltaX,$row * $deltaY);
  $column += 1;
  if ($column > 5)
   {
    $column = 1;
    $row += 1;
   }
 }
$camera->SetViewUp(0,1,0);
$camera->SetFocalPoint(0,0,0);
$camera->SetPosition(1,0,0);
$camera->ComputeViewPlaneNormal;
$ren{100}->ResetCamera;
$camera->Dolly(1.25);
$ren{100}->ResetCameraClippingRange;
$ren{110}->ResetCameraClippingRange;
$ren{120}->ResetCameraClippingRange;
$ren{130}->ResetCameraClippingRange;
$ren{140}->ResetCameraClippingRange;
$ren{144}->ResetCameraClippingRange;
$ren{153}->ResetCameraClippingRange;
$ren{163}->ResetCameraClippingRange;
$ren{170}->ResetCameraClippingRange;
$ren{184}->ResetCameraClippingRange;
$light->SetPosition($camera->GetPosition);
$light->SetFocalPoint($camera->GetFocalPoint);
$renWin->SetSize(600,180);
$renWin->Render;
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->SetFileName("Plot3DScalars.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
