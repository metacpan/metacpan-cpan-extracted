#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates how to use a programmable filter and how to use
# the special vtkDataSetToDataSet::GetOutput() methods

# first we load in the standard vtk packages into tcl
$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;


# We create a 100 by 100 point plane to sample 

$plane = Graphics::VTK::PlaneSource->new;
$plane->SetXResolution(100);
$plane->SetYResolution(100);


# We transform the plane by a factor of 10 on X and Y

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


# The SetExecuteMethod takes a Tcl proc as an argument
# In here is where all the processing is done.

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
 $derivs = Graphics::VTK::FloatArray->new;

 for ($i = 0; $i < $numPts; $i += 1)
  {
@x = $input->GetPoint($i);
   $x0 = $x[0];
   $x1 = $x[1];

   $r = sqrt($x0 * $x0 + $x1 * $x1);
   $x2 = exp(-$r) * cos(10.0 * $r);
   $deriv = (-exp(-$r)) * (cos(10.0 * $r) + 10.0 * sin(10.0 * $r));

   $newPts->InsertPoint($i,$x0,$x1,$x2);
   $derivs->InsertValue($i,$deriv);
  }

 $besselF->GetPolyDataOutput->CopyStructure($input);
 $besselF->GetPolyDataOutput->SetPoints($newPts);
 $besselF->GetPolyDataOutput->GetPointData->SetScalars($derivs);


 #reference counting - it's ok

}


# We warp the plane based on the scalar values calculated above

$warp = Graphics::VTK::WarpScalar->new;
$warp->SetInput($besselF->GetPolyDataOutput);
$warp->XYPlaneOn;
$warp->SetScaleFactor(0.5);


# We create a mapper and actor as usual. In the case we adjust the 
# scalar range of the mapper to match that of the computed scalars

$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($warp->GetPolyDataOutput);
$mapper->SetScalarRange($besselF->GetPolyDataOutput->GetScalarRange);
$carpet = Graphics::VTK::Actor->new;
$carpet->SetMapper($mapper);


# Create the RenderWindow, Renderer

$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

$ren1->AddActor($carpet);
$renWin->SetSize(500,500);

# render the image

$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$ren1->GetActiveCamera->Zoom(1.5);
$renWin->Render;

# prevent the tk window from showing up then start the event loop
$MW->withdraw;

Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
