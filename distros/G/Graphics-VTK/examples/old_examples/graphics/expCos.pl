#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates how to use a programmable filter and how to use
# the special vtkDataSetToDataSet::GetOutput() methods (i.e., see vtkWarpScalar)
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# create pipeline
# create plane to warp
$plane = Graphics::VTK::PlaneSource->new;
$plane->SetXResolution(100);
$plane->SetYResolution(100);
$transform = Graphics::VTK::Transform->new;
$transform->Scale(10,10,1);
$transF = Graphics::VTK::TransformPolyDataFilter->new;
$transF->SetInput($plane->GetOutput);
$transF->SetTransform($transform);
# Compute Bessel function and derivatives. We'll use a programmable filter
# for this. Note the unusual GetInput() & GetOutput() methods.
$besselF = Graphics::VTK::ProgrammableFilter->new;
$besselF->SetInput($transF->GetOutput);
$besselF->SetExecuteMethod(
 sub
  {
   bessel();
  }
);
#
sub bessel
{
 my $deriv;
 my $derivs;
 my $i;
 my $input;
 my $newPts;
 my $numPts;
 my $r;
 my $x;
 my $x0;
 my $x1;
 my $x2;
 $input = $besselF->GetPolyDataInput;
 $numPts = $input->GetNumberOfPoints;
 $newPts = Graphics::VTK::Points->new;
 $derivs = Graphics::VTK::Scalars->new;
 for ($i = 0; $i < $numPts; $i += 1)
  {
   $x = $input->GetPoint($i);
   $x0 = $x[0];
   $x1 = $x[1];
   $r = sqrt($x0 * $x0 + $x1 * $x1);
   $x2 = exp(-$r) * cos(10.0 * $r);
   $deriv = (-exp(-$r)) * (cos(10.0 * $r) + 10.0 * sin(10.0 * $r));
   $newPts->InsertPoint($i,$x0,$x1,$x2);
   $derivs->InsertScalar($i,$deriv);
  }
 $besselF->GetPolyDataOutput->CopyStructure($input);
 $besselF->GetPolyDataOutput->SetPoints($newPts);
 $besselF->GetPolyDataOutput->GetPointData->SetScalars($derivs);

 #reference counting - it's ok

}
# warp plane
$warp = Graphics::VTK::WarpScalar->new;
$warp->SetInput($besselF->GetPolyDataOutput);
$warp->XYPlaneOn;
$warp->SetScaleFactor(0.5);
# mapper and actor
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($warp->GetPolyDataOutput);
$mapper->SetScalarRange($besselF->GetPolyDataOutput->GetScalarRange);
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
#renWin SetFileName "expCos.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
