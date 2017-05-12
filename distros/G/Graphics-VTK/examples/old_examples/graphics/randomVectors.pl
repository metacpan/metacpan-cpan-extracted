#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates how to use a programmable point data filter and how to use
# the special vtkDataSetToDataSet::GetOutput() methods (i.e., see vtkWarpScalar)
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# create pipeline
# create plane to warp
$plane = Graphics::VTK::PlaneSource->new;
$plane->SetXResolution(25);
$plane->SetYResolution(25);
$transform = Graphics::VTK::Transform->new;
$transform->Scale(10,10,1);
$transF = Graphics::VTK::TransformPolyDataFilter->new;
$transF->SetInput($plane->GetOutput);
$transF->SetTransform($transform);
# Generate random vectors perpendicular to the plane. Also create random scalars.
# Note the unsual GetInput() & GetOutput() methods.
$randomF = Graphics::VTK::ProgrammableAttributeDataFilter->new;
$randomF->SetInput($transF->GetOutput);
$randomF->SetExecuteMethod(
 sub
  {
   randomVectors();
  }
);
#
sub randomVectors
{
 my $i;
 my $input;
 my $math;
 my $newPts;
 my $numPts;
 my $s;
 my $scalars;
 my $vectors;
 my $x;
 my $x0;
 my $x1;
 $input = $randomF->GetInput;
 $numPts = $input->GetNumberOfPoints;
 $math = Graphics::VTK::Math->new;
 $newPts = Graphics::VTK::Points->new;
 $scalars = Graphics::VTK::Scalars->new;
 $vectors = Graphics::VTK::Vectors->new;
 for ($i = 0; $i < $numPts; $i += 1)
  {
   $x = $input->GetPoint($i);
   $x0 = $x[0];
   $x1 = $x[1];
   $s = $math->Random(0,1);
   $scalars->InsertScalar($i,$s);
   $vectors->InsertVector($i,0,0,$s);
  }
 $randomF->GetOutput->GetPointData->SetScalars($scalars);
 $randomF->GetOutput->GetPointData->SetVectors($vectors);

 #reference counting - it's ok



}
# warp plane
$warp = Graphics::VTK::WarpVector->new;
$warp->SetInput($randomF->GetPolyDataOutput);
$warp->SetScaleFactor(0.5);
# mapper and actor
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($warp->GetPolyDataOutput);
$mapper->SetScalarRange($randomF->GetPolyDataOutput->GetScalarRange);
$carpet = Graphics::VTK::Actor->new;
$carpet->SetMapper($mapper);
# assign our actor to the renderer
# Create graphics stuff
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($carpet);
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
#renWin SetFileName "valid/expCos.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
