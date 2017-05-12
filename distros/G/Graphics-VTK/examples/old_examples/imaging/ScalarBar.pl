#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates how to use cell data as well as the programmable attribute 
# filter. Example randomly colors cells with scalar values.
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# create pipeline
# create sphere to color
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetThetaResolution(20);
$sphere->SetPhiResolution(40);
# Compute random scalars (colors) for each cell
$randomColors = Graphics::VTK::ProgrammableAttributeDataFilter->new;
$randomColors->SetInput($sphere->GetOutput);
$randomColors->SetExecuteMethod(
 sub
  {
   colorCells();
  }
);
#
sub colorCells
{
 my $colors;
 my $i;
 my $input;
 my $numCells;
 my $output;
 my $randomColorGenerator;
 $randomColorGenerator = Graphics::VTK::Math->new;
 $input = $randomColors->GetInput;
 $output = $randomColors->GetOutput;
 $numCells = $input->GetNumberOfCells;
 $colors = Graphics::VTK::Scalars->new;
 $colors->SetNumberOfScalars($numCells);
 for ($i = 0; $i < $numCells; $i += 1)
  {
   $colors->SetScalar($i,$randomColorGenerator->Random(0,1));
  }
 $output->GetCellData->CopyScalarsOff;
 $output->GetCellData->PassData($input->GetCellData);
 $output->GetCellData->SetScalars($colors);

 #reference counting - it's ok

}
# mapper and actor
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($randomColors->GetPolyDataOutput);
$mapper->SetScalarRange($randomColors->GetPolyDataOutput->GetScalarRange);
$sphereActor = Graphics::VTK::Actor->new;
$sphereActor->SetMapper($mapper);
# Create a scalar bar
$scalarBar = Graphics::VTK::ScalarBarActor->new;
$scalarBar->SetLookupTable($mapper->GetLookupTable);
$scalarBar->SetTitle("Temperature");
$scalarBar->GetPositionCoordinate->SetCoordinateSystemToNormalizedViewport;
$scalarBar->GetPositionCoordinate->SetValue(0.1,0.01);
$scalarBar->SetOrientationToHorizontal;
$scalarBar->SetWidth(0.8);
$scalarBar->SetHeight(0.17);
# Create graphics stuff
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($sphereActor);
$ren1->AddActor2D($scalarBar);
$renWin->SetSize(500,500);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$ren1->GetActiveCamera->Zoom(1.5);
$renWin->Render;
$scalarBar->SetNumberOfLabels(8);
$renWin->Render;
#renWin SetFileName "ScalarBar.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
