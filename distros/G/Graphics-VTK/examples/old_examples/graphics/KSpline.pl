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
$aSplineX = Graphics::VTK::KochanekSpline->new;
$aSplineY = Graphics::VTK::KochanekSpline->new;
$aSplineZ = Graphics::VTK::KochanekSpline->new;
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
$points = Graphics::VTK::Points->new;
# create a line
$tension = 0;
$bias = 0;
$continuity = 0;
$aSplineX->SetDefaultTension($tension);
$aSplineX->SetDefaultBias($bias);
$aSplineX->SetDefaultContinuity($continuity);
$aSplineY->SetDefaultTension($tension);
$aSplineY->SetDefaultBias($bias);
$aSplineY->SetDefaultContinuity($continuity);
$aSplineZ->SetDefaultTension($tension);
$aSplineZ->SetDefaultBias($bias);
$aSplineZ->SetDefaultContinuity($continuity);
$profileData = Graphics::VTK::PolyData->new;
$numberOfOutputPoints = 300;
$offset = 1.0;
#
sub fit
{
 my $i;
 my $t;
 # Global Variables Declared for this function: numberOfInputPoints, numberOfOutputPoints, offset
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
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
#
sub defaults
{
 my $fit;
 $aSplineX->SetDefaultBias(0);
 $aSplineX->SetDefaultTension(0);
 $aSplineX->SetDefaultContinuity(0);
 $aSplineY->SetDefaultBias(0);
 $aSplineY->SetDefaultTension(0);
 $aSplineY->SetDefaultContinuity(0);
 $aSplineZ->SetDefaultBias(0);
 $aSplineZ->SetDefaultTension(0);
 $aSplineZ->SetDefaultContinuity(0);
 fit();
 $renWin->Render;
}
#
sub varyBias
{
 my $bias;
 my $defaults;
 my $fit;
 defaults();
 for ($bias = -1; $bias <= 1; $bias = $bias + '.05')
  {
   $aSplineX->SetDefaultBias($bias);
   $aSplineY->SetDefaultBias($bias);
   $aSplineZ->SetDefaultBias($bias);
   fit();
   $renWin->Render;
  }
}
#
sub varyTension
{
 my $defaults;
 my $fit;
 my $tension;
 defaults();
 for ($tension = -1; $tension <= 1; $tension = $tension + '.05')
  {
   $aSplineX->SetDefaultTension($tension);
   $aSplineY->SetDefaultTension($tension);
   $aSplineZ->SetDefaultTension($tension);
   fit();
   $renWin->Render;
  }
}
#
sub varyContinuity
{
 my $Continuity;
 my $defaults;
 my $fit;
 defaults();
 for ($Continuity = -1; $Continuity <= 1; $Continuity = $Continuity + '.05')
  {
   $aSplineX->SetDefaultContinuity($Continuity);
   $aSplineY->SetDefaultContinuity($Continuity);
   $aSplineZ->SetDefaultContinuity($Continuity);
   fit();
   $renWin->Render;
  }
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
$renWin->SetFileName('KSpline.tcl.ppm');
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
