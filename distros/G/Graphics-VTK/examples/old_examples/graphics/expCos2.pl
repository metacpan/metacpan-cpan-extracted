#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates how to use a programmable source and how to use
# the special vtkDataSetToDataSet::GetOutput() methods (i.e., see vtkWarpScalar)
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# create pipeline - use a programmable source to compute Bessel function and
# generate a plane of quadrilateral polygons,
$besselSource = Graphics::VTK::ProgrammableSource->new;
$besselSource->SetExecuteMethod(
 sub
  {
   bessel();
  }
);
# Generate plane with Bessel function scalar values.
# It's interesting to compare this with vtkPlaneSource.
#
sub bessel
{
 my $XOrigin;
 my $XRes;
 my $XWidth;
 my $YOrigin;
 my $YRes;
 my $YWidth;
 my $deriv;
 my $derivs;
 my $i;
 my $id;
 my $j;
 my $newPolys;
 my $newPts;
 my $r;
 my $x0;
 my $x1;
 my $x2;
 $XRes = 25;
 $XOrigin = -5.0;
 $XWidth = 10.0;
 $YRes = 40;
 $YOrigin = -5.0;
 $YWidth = 10.0;
 $newPts = Graphics::VTK::Points->new;
 $newPolys = Graphics::VTK::CellArray->new;
 $derivs = Graphics::VTK::Scalars->new;
 # Compute points and scalars
 for ((($id = 0),($j = 0)); $j < $YRes + 1; $j += 1)
  {
   $x1 = $YOrigin + ($j / $YRes) * $YWidth;
   for ($i = 0; $i < $XRes + 1; (($i += 1),($id += 1)))
    {
     $x0 = $XOrigin + ($i / $XRes) * $XWidth;
     $r = sqrt($x0 * $x0 + $x1 * $x1);
     $x2 = exp(-$r) * cos(10.0 * $r);
     $deriv = (-exp(-$r)) * (cos(10.0 * $r) + 10.0 * sin(10.0 * $r));
     $newPts->InsertPoint($id,$x0,$x1,$x2);
     $derivs->InsertScalar($id,$deriv);
    }
  }
 # Generate polygon connectivity
 for ($j = 0; $j < $YRes; $j += 1)
  {
   for ($i = 0; $i < $XRes; $i += 1)
    {
     $newPolys->InsertNextCell(4);
     $id = $i + $j * ($XRes + 1);
     $newPolys->InsertCellPoint($id);
     $newPolys->InsertCellPoint($id + 1);
     $newPolys->InsertCellPoint($id + $XRes + 2);
     $newPolys->InsertCellPoint($id + $XRes + 1);
    }
  }
 $besselSource->GetPolyDataOutput->SetPoints($newPts);
 $besselSource->GetPolyDataOutput->SetPolys($newPolys);
 $besselSource->GetPolyDataOutput->GetPointData->SetScalars($derivs);

 #reference counting - it's ok


}
# warp plane
$warp = Graphics::VTK::WarpScalar->new;
$warp->SetInput($besselSource->GetPolyDataOutput);
$warp->XYPlaneOn;
$warp->SetScaleFactor(0.5);
# mapper and actor
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($warp->GetPolyDataOutput);
$mapper->SetScalarRange($besselSource->GetPolyDataOutput->GetScalarRange);
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
#renWin SetFileName "expCos2.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
