#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates the use of vtkCardinalSpline.
# It creates random points and connects them with a spline


# First we include the VTK Tcl packages which will make available 
# all of the vtk commands to Tcl

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;

# This will be used later to get random numbers.
$math = Graphics::VTK::Math->new;

# Total number of points.
$numberOfInputPoints = 10;

# One spline for each direction.
$aSplineX = Graphics::VTK::CardinalSpline->new;
$aSplineY = Graphics::VTK::CardinalSpline->new;
$aSplineZ = Graphics::VTK::CardinalSpline->new;

# Generate random (pivot) points and add the corresponding 
# coordinates to the splines.
# aSplineX will interpolate the x values of the points
# aSplineY will interpolate the y values of the points
# aSplineZ will interpolate the z values of the points
$inputPoints = Graphics::VTK::Points->new;
for ($i = 0; $i < $numberOfInputPoints; $i += 1)
 {
  $x = $math->Random(0,1);
  $y = $math->Random(0,1);
  $z = $math->Random(0,1);
  $aSplineX->AddPoint($i,$x);
  $aSplineY->AddPoint($i,$y);
  $aSplineZ->AddPoint($i,$z);
  $inputPoints->InsertPoint($i,$x,$y,$z);
 }

# The following section will create glyphs for the pivot points
# in order to make the effect of the spline more clear.

# Create a polydata to be glyphed.
$inputData = Graphics::VTK::PolyData->new;
$inputData->SetPoints($inputPoints);

# Use sphere as glyph source.
$balls = Graphics::VTK::SphereSource->new;
$balls->SetRadius('.01');
$balls->SetPhiResolution(10);
$balls->SetThetaResolution(10);

$glyphPoints = Graphics::VTK::Glyph3D->new;
$glyphPoints->SetInput($inputData);
$glyphPoints->SetSource($balls->GetOutput);

$glyphMapper = Graphics::VTK::PolyDataMapper->new;
$glyphMapper->SetInput($glyphPoints->GetOutput);

$glyph = Graphics::VTK::Actor->new;
$glyph->SetMapper($glyphMapper);
$glyph->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::tomato);
$glyph->GetProperty->SetSpecular('.3');
$glyph->GetProperty->SetSpecularPower(30);

# Generate the polyline for the spline.
$points = Graphics::VTK::Points->new;
$profileData = Graphics::VTK::PolyData->new;

# Number of points on the spline
$numberOfOutputPoints = 400;

# Interpolate x, y and z by using the three spline filters and
# create new points
for ($i = 0; $i < $numberOfOutputPoints; $i += 1)
 {
  $t = ($numberOfInputPoints - 1.0) / ($numberOfOutputPoints - 1.0) * $i;
  $points->InsertPoint($i,$aSplineX->Evaluate($t),$aSplineY->Evaluate($t),$aSplineZ->Evaluate($t));
 }

# Create the polyline.
$lines = Graphics::VTK::CellArray->new;
$lines->InsertNextCell($numberOfOutputPoints);
for ($i = 0; $i < $numberOfOutputPoints; $i += 1)
 {
  $lines->InsertCellPoint($i);
 }
$profileData->SetPoints($points);
$profileData->SetLines($lines);

# Add thickness to the resulting line.
$profileTubes = Graphics::VTK::TubeFilter->new;
$profileTubes->SetNumberOfSides(8);
$profileTubes->SetInput($profileData);
$profileTubes->SetRadius('.005');

$profileMapper = Graphics::VTK::PolyDataMapper->new;
$profileMapper->SetInput($profileTubes->GetOutput);

$profile = Graphics::VTK::Actor->new;
$profile->SetMapper($profileMapper);
$profile->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::banana);
$profile->GetProperty->SetSpecular('.3');
$profile->GetProperty->SetSpecularPower(30);


# Now create the RenderWindow, Renderer and Interactor

$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);

$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors
$ren1->AddActor($glyph);
$ren1->AddActor($profile);

$renWin->SetSize(500,500);

# render the image

$iren->Initialize;
$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);

# prevent the tk window from showing up
$MW->withdraw;


Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
