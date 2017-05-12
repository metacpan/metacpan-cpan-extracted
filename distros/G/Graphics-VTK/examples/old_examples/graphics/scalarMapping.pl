#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates how to control mapper to use cell scalars or point scalars.
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
$pointScalars = Graphics::VTK::CellDataToPointData->new;
$pointScalars->SetInput($randomColors->GetOutput);
$pointScalars->PassCellDataOn;
# create two spheres which render cell scalars and point scalars
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($pointScalars->GetPolyDataOutput);
$mapper->SetScalarRange($randomColors->GetPolyDataOutput->GetScalarRange);
$mapper->SetScalarModeToUseCellData;
$sphereActor = Graphics::VTK::Actor->new;
$sphereActor->SetMapper($mapper);
$mapper2 = Graphics::VTK::PolyDataMapper->new;
$mapper2->SetInput($pointScalars->GetPolyDataOutput);
$mapper2->SetScalarRange($randomColors->GetPolyDataOutput->GetScalarRange);
$mapper2->SetScalarModeToUsePointData;
$sphereActor2 = Graphics::VTK::Actor->new;
$sphereActor2->SetMapper($mapper2);
$sphereActor2->AddPosition(1,0,0);
# Create graphics stuff
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($sphereActor);
$ren1->AddActor($sphereActor2);
$renWin->SetSize(400,250);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$ren1->GetActiveCamera->Zoom(2.5);
$renWin->Render;
$renWin->SetFileName("scalarMapping.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
