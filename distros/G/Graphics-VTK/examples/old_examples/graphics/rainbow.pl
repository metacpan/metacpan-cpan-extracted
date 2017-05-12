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
# create planes
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create pipeline
$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA/combxyz.bin");
$pl3d->SetQFileName("$VTK_DATA/combq.bin");
$pl3d->SetScalarFunctionNumber(100);
$pl3d->SetVectorFunctionNumber(202);
$pl3d->Update;
$plane = Graphics::VTK::StructuredGridGeometryFilter->new;
$plane->SetInput($pl3d->GetOutput);
$plane->SetExtent(1,100,1,100,7,7);
$lut = Graphics::VTK::LookupTable->new;
$planeMapper = Graphics::VTK::PolyDataMapper->new;
$planeMapper->SetLookupTable($lut);
$planeMapper->SetInput($plane->GetOutput);
$planeMapper->SetScalarRange(0.197813,0.710419);
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($planeMapper);
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineProp = $outlineActor->GetProperty;
#eval $outlineProp SetColor $black
# different lookup tables for each figure
#black to white lut
#    lut SetHueRange 0 0
#    lut SetSaturationRange 0 0
#    lut SetValueRange 0.2 1.0
#red to blue lut
#    lut SetHueRange 0.0 0.667
#blue to red lut
#    lut SetHueRange 0.667 0.0
#funky constrast
$lut->SetNumberOfColors(256);
$lut->Build;
for ($i = 0; $i < 16; $i += 1)
 {
  $lut->SetTableValue($i * 16,$red,1);
  $lut->SetTableValue($i * 16 + 1,$green,1);
  $lut->SetTableValue($i * 16 + 2,$blue,1);
  $lut->SetTableValue($i * 16 + 3,$black,1);
 }
#    eval lut SetTableValue 0 $coral 1
#    eval lut SetTableValue 1 $black 1
#    eval lut SetTableValue 2 $peacock 1
#    eval lut SetTableValue 3 $black 1
#    eval lut SetTableValue 4 $orchid 1
#    eval lut SetTableValue 5 $black 1
#    eval lut SetTableValue 6 $cyan 1
#    eval lut SetTableValue 7 $black 1
#    eval lut SetTableValue 8 $mint 1
#    eval lut SetTableValue 9 $black 1
#    eval lut SetTableValue 10 $tomato 1
#    eval lut SetTableValue 11 $black 1
#    eval lut SetTableValue 12 $sea_green 1
#    eval lut SetTableValue 13 $black 1
#    eval lut SetTableValue 14 $plum 1
#    eval lut SetTableValue 15 $black 1
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($planeActor);
#ren1 SetBackground 1 1 1
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(500,500);
$renWin->DoubleBufferOn;
$iren->Initialize;
$renWin->Render;
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(3.95297,50);
$cam1->SetFocalPoint(8.88908,0.595038,29.3342);
$cam1->SetPosition(-12.3332,31.7479,41.2387);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(0.060772,-0.319905,0.945498);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
#renWin SetFileName "rainbow.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
