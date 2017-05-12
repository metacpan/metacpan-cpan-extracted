#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version of plate vibration
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# read a vtk file
$plate = Graphics::VTK::PolyDataReader->new;
$plate->SetFileName("$VTK_DATA/plate.vtk");
$plate->SetVectorsName("mode8");
$warp = Graphics::VTK::WarpVector->new;
$warp->SetInput($plate->GetOutput);
$warp->SetScaleFactor(0.5);
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($warp->GetPolyDataOutput);
$color = Graphics::VTK::VectorDot->new;
$color->SetInput($normals->GetOutput);
$lut = Graphics::VTK::LookupTable->new;
$lut->SetNumberOfColors(256);
$lut->Build;
for ($i = 0; $i < 128; $i += 1)
 {
  $lut->SetTableValue($i,(128.0 - $i) / 128.0,(128.0 - $i) / 128.0,(128.0 - $i) / 128.0,1);
 }
for ($i = 128; $i < 256; $i += 1)
 {
  $lut->SetTableValue($i,($i - 128.0) / 128.0,($i - 128.0) / 128.0,($i - 128.0) / 128.0,1);
 }
$plateMapper = Graphics::VTK::DataSetMapper->new;
$plateMapper->SetInput($color->GetOutput);
$plateMapper->SetLookupTable($lut);
$plateMapper->SetScalarRange(-1,1);
$plateActor = Graphics::VTK::Actor->new;
$plateActor->SetMapper($plateMapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($plateActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
#renWin SetFileName "dispPlot.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
