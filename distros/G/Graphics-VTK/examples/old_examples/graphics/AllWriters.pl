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
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# read data
$input = Graphics::VTK::PolyDataReader->new;
$input->SetFileName("$VTK_DATA/brainImageSmooth.vtk");
# generate vectors
$clean = Graphics::VTK::CleanPolyData->new;
$clean->SetInput($input->GetOutput);
$smooth = Graphics::VTK::WindowedSincPolyDataFilter->new;
$smooth->SetInput($clean->GetOutput);
$smooth->GenerateErrorVectorsOn;
$smooth->GenerateErrorScalarsOn;
$smooth->Update;
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($smooth->GetOutput);
$mapper->SetScalarRange($smooth->GetOutput->GetScalarRange);
$brain = Graphics::VTK::Actor->new;
$brain->SetMapper($mapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($brain);
$renWin->SetSize(320,240);
$cam1 = $ren1->GetActiveCamera;
$cam1->SetPosition(152.589,-135.901,173.068);
$cam1->SetFocalPoint(146.003,22.3839,0.260541);
$cam1->SetViewUp(-0.255578,-0.717754,-0.647695);
$ren1->ResetCameraClippingRange;
$iren->Initialize;
$renWin->Render;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
#renWin SetFileName writers.tcl.ppm
#renWin SaveImageAsPPM
# test the writers
$dsw = Graphics::VTK::DataSetWriter->new;
$dsw->SetInput($smooth->GetOutput);
$dsw->SetFileName('brain.dsw');
$dsw->Write;
$pdw = Graphics::VTK::PolyDataWriter->new;
$pdw->SetInput($smooth->GetOutput);
$pdw->SetFileName('brain.pdw');
$pdw->Write;
if (Graphics::VTK::IVWriter->can('new') ne "")
 {
  $iv = Graphics::VTK::IVWriter->new;
  $iv->SetInput($smooth->GetOutput);
  $iv->SetFileName('brain.iv');
  $iv->Write;
 }
# the next writers only handle triangles
$triangles = Graphics::VTK::TriangleFilter->new;
$triangles->SetInput($smooth->GetOutput);
if (Graphics::VTK::IVWriter->can('new') ne "")
 {
  $iv2 = Graphics::VTK::IVWriter->new;
  $iv2->SetInput($triangles->GetOutput);
  $iv2->SetFileName('brain2.iv');
  $iv2->Write;
 }
if (Graphics::VTK::IVWriter->can('new') ne "")
 {
  $edges = Graphics::VTK::ExtractEdges->new;
  $edges->SetInput($triangles->GetOutput);
  $iv3 = Graphics::VTK::IVWriter->new;
  $iv3->SetInput($edges->GetOutput);
  $iv3->SetFileName('brain3.iv');
  $iv3->Write;
 }
$byu = Graphics::VTK::BYUWriter->new;
$byu->SetGeometryFileName('brain.g');
$byu->SetScalarFileName('brain.s');
$byu->SetDisplacementFileName('brain.d');
$byu->SetInput($triangles->GetOutput);
$byu->Write;
$mcubes = Graphics::VTK::MCubesWriter->new;
$mcubes->SetInput($triangles->GetOutput);
$mcubes->SetFileName('brain.tri');
$mcubes->SetLimitsFileName('brain.lim');
$mcubes->Write;
$stl = Graphics::VTK::STLWriter->new;
$stl->SetInput($triangles->GetOutput);
$stl->SetFileName('brain.stl');
$stl->Write;
$stlBinary = Graphics::VTK::STLWriter->new;
$stlBinary->SetInput($triangles->GetOutput);
$stlBinary->SetFileName('brainBinary.stl');
$stlBinary->SetFileType(2);
$stlBinary->Write;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
