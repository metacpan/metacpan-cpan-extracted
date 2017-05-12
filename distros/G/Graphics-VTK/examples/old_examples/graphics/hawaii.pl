#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version of hawaii coloration
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# read a vtk file
$hawaii = Graphics::VTK::PolyDataReader->new;
$hawaii->SetFileName("$VTK_DATA/honolulu.vtk");
$hawaii->Update;
$elevation = Graphics::VTK::ElevationFilter->new;
$elevation->SetInput($hawaii->GetOutput);
$elevation->SetLowPoint(0,0,0);
$elevation->SetHighPoint(0,0,1000);
$elevation->SetScalarRange(0,1000);
$lut = Graphics::VTK::LookupTable->new;
$lut->SetHueRange(0.7,0);
$lut->SetSaturationRange(1.0,0);
$lut->SetValueRange(0.5,1.0);
#    lut SetNumberOfColors 8
#    lut Build
#    eval lut SetTableValue 0 $turquoise_blue 1
#    eval lut SetTableValue 1 $sea_green_medium 1
#    eval lut SetTableValue 2 $sea_green_dark 1
#    eval lut SetTableValue 3 $olive_green_dark 1
#    eval lut SetTableValue 4 $brown 1
#    eval lut SetTableValue 5 $beige 1
#    eval lut SetTableValue 6 $light_beige 1
#    eval lut SetTableValue 7 $bisque 1
$hawaiiMapper = Graphics::VTK::DataSetMapper->new;
$hawaiiMapper->SetInput($elevation->GetOutput);
$hawaiiMapper->SetScalarRange(0,1000);
$hawaiiMapper->SetLookupTable($lut);
$hawaiiMapper->ImmediateModeRenderingOn;
$hawaiiActor = Graphics::VTK::Actor->new;
$hawaiiActor->SetMapper($hawaiiMapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($hawaiiActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$renWin->DoubleBufferOff;
$ren1->SetBackground(0.1,0.2,0.4);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$ren1->GetActiveCamera->Zoom(1.8);
$renWin->Render;
#renWin SetFileName "hawaii.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
