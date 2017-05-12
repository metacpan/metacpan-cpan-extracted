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
# Now create the RenderWindow, Renderer and Interactor
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$math = Graphics::VTK::Math->new;
$numberOfInputPoints = 30;
$aSplineX = Graphics::VTK::CardinalSpline->new;
$aSplineY = Graphics::VTK::CardinalSpline->new;
$aSplineZ = Graphics::VTK::CardinalSpline->new;
# generate random points
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
$inputData = Graphics::VTK::PolyData->new;
$inputData->SetPoints($inputPoints);
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
$ren1->AddActor($glyph);
# create a polyline
$points = Graphics::VTK::Points->new;
$profileData = Graphics::VTK::PolyData->new;
$numberOfOutputPoints = 400;
$offset = 1.0;
#
sub fit
{
 my $i;
 my $t;
 # Global Variables Declared for this function: numberOfInputPoints, numberOfOutputPoints, offset, points, aSplineX, aSplineY, aSplineZ, profileData
 $points->Reset;
 for ($i = 0; $i < $numberOfOutputPoints; $i += 1)
  {
   $t = ($numberOfInputPoints - $offset) / ($numberOfOutputPoints - 1) * $i;
   $points->InsertPoint($i,$aSplineX->Evaluate($t),$aSplineY->Evaluate($t),$aSplineZ->Evaluate($t));
  }
 $profileData->Modified;
}
fit();
$lines = Graphics::VTK::CellArray->new;
$lines->InsertNextCell($numberOfOutputPoints);
for ($i = 0; $i < $numberOfOutputPoints; $i += 1)
 {
  $lines->InsertCellPoint($i);
 }
$profileData->SetPoints($points);
$profileData->SetLines($lines);
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
$ren1->AddActor($profile);
$ren1->GetActiveCamera->Dolly(1.5);
$ren1->ResetCameraClippingRange;
$renWin->SetSize(500,500);
# render the image
$iren->Initialize;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
#
sub opened
{
 my $fit;
 # Global Variables Declared for this function: offset
 $offset = 1.0;
 $aSplineX->ClosedOff;
 $aSplineY->ClosedOff;
 $aSplineZ->ClosedOff;
 fit();
 $renWin->Render;
}
#
sub varyLeft
{
 my $fit;
 my $left;
 for ($left = -1; $left <= 1; $left = $left + '.05')
  {
   $aSplineX->SetLeftValue($left);
   $aSplineY->SetLeftValue($left);
   $aSplineZ->SetLeftValue($left);
   fit();
   $renWin->Render;
  }
}
#
sub varyRight
{
 my $fit;
 my $right;
 for ($right = -1; $right <= 1; $right = $right + '.05')
  {
   $aSplineX->SetRightValue($right);
   $aSplineY->SetRightValue($right);
   $aSplineZ->SetRightValue($right);
   fit();
   $renWin->Render;
  }
}
#
sub constraint
{
 my $value = shift;
 $aSplineX->SetLeftConstraint($value);
 $aSplineY->SetLeftConstraint($value);
 $aSplineZ->SetLeftConstraint($value);
 $aSplineX->SetRightConstraint($value);
 $aSplineY->SetRightConstraint($value);
 $aSplineZ->SetRightConstraint($value);
}
#
sub closed
{
 my $fit;
 # Global Variables Declared for this function: offset
 $offset = 0.0;
 $aSplineX->ClosedOn;
 $aSplineY->ClosedOn;
 $aSplineZ->ClosedOn;
 fit();
 $renWin->Render;
}
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
#$renWin->SetFileName('CSpline.tcl.ppm');
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
