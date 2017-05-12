#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# include get the vtk interactor ui
use Graphics::VTK::Tk::vtkInt;
# create pipeline
# create sphere to color
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetThetaResolution(0);
$sphere->SetPhiResolution(0);
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
   $colors->SetScalar($i,$randomColorGenerator->Random('.1','.9'));
  }
 $output->GetCellData->CopyScalarsOff;
 $output->GetCellData->PassData($input->GetCellData);
 $output->GetCellData->SetScalars($colors);

 #reference counting - it's ok

}
$randomColors->GetOutput->GetPointData->CopyNormalsOff;
$linear = Graphics::VTK::ButterflySubdivisionFilter->new;
$linear->SetInput($randomColors->GetPolyDataOutput);
$linear->SetNumberOfSubdivisions(4);
# mapper and actor
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($linear->GetOutput);
$mapper->SetScalarRange($randomColors->GetPolyDataOutput->GetScalarRange);
$sphereActor = Graphics::VTK::Actor->new;
$sphereActor->SetMapper($mapper);
$sphereActor->GetProperty->SetDiffuse('.7');
$sphereActor->GetProperty->SetSpecular('.4');
$sphereActor->GetProperty->SetSpecularPower(60);
# Create graphics stuff
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($sphereActor);
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
$renWin->SetFileName("subdivideCellColors.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
