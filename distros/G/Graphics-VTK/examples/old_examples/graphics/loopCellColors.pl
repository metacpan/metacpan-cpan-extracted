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
$sphere->SetThetaResolution(5);
$sphere->SetPhiResolution(5);
$sphere->SetStartTheta(90);
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
$loopApprox = Graphics::VTK::LoopSubdivisionFilter->new;
$loopApprox->SetInput($randomColors->GetPolyDataOutput);
$loopApprox->SetNumberOfSubdivisions(4);
# mapper and actor
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($loopApprox->GetOutput);
$mapper->SetScalarRange($randomColors->GetPolyDataOutput->GetScalarRange);
$sphereActor = Graphics::VTK::Actor->new;
$sphereActor->SetMapper($mapper);
$sphereActor->GetProperty->SetDiffuse('.7');
$sphereActor->GetProperty->SetSpecular('.3');
$sphereActor->GetProperty->SetSpecularPower(20);
$edges = Graphics::VTK::ExtractEdges->new;
$edges->SetInput($sphere->GetOutput);
$tubes = Graphics::VTK::TubeFilter->new;
$tubes->SetInput($edges->GetOutput);
$tubes->SetRadius('.005');
$tubes->SetNumberOfSides(8);
$tubeMapper = Graphics::VTK::PolyDataMapper->new;
$tubeMapper->SetInput($tubes->GetOutput);
$tubeActor = Graphics::VTK::Actor->new;
$tubeActor->SetMapper($tubeMapper);
# Create graphics stuff
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$ren1->SetBackground('.1','.2','.4');
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($sphereActor);
$ren1->AddActor($tubeActor);
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
$renWin->SetFileName("loopCellColors.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
