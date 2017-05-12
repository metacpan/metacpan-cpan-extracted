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
$aKSplineX = Graphics::VTK::KochanekSpline->new;
$aKSplineX->ClosedOn;
$aKSplineY = Graphics::VTK::KochanekSpline->new;
$aKSplineY->ClosedOn;
$aKSplineZ = Graphics::VTK::KochanekSpline->new;
$aKSplineZ->ClosedOn;
$aCSplineX = Graphics::VTK::CardinalSpline->new;
$aCSplineX->ClosedOn;
$aCSplineY = Graphics::VTK::CardinalSpline->new;
$aCSplineY->ClosedOn;
$aCSplineZ = Graphics::VTK::CardinalSpline->new;
$aCSplineZ->ClosedOn;
# add some points
$inputPoints = Graphics::VTK::Points->new;
$x = -1.0;
$y = -1.0;
$z = 0.0;
$aKSplineX->AddPoint(0,$x);
$aKSplineY->AddPoint(0,$y);
$aKSplineZ->AddPoint(0,$z);
$aCSplineX->AddPoint(0,$x);
$aCSplineY->AddPoint(0,$y);
$aCSplineZ->AddPoint(0,$z);
$inputPoints->InsertPoint(0,$x,$y,$z);
$x = 1.0;
$y = -1.0;
$z = 0.0;
$aKSplineX->AddPoint(1,$x);
$aKSplineY->AddPoint(1,$y);
$aKSplineZ->AddPoint(1,$z);
$aCSplineX->AddPoint(1,$x);
$aCSplineY->AddPoint(1,$y);
$aCSplineZ->AddPoint(1,$z);
$inputPoints->InsertPoint(1,$x,$y,$z);
$x = 1.0;
$y = 1.0;
$z = 0.0;
$aKSplineX->AddPoint(2,$x);
$aKSplineY->AddPoint(2,$y);
$aKSplineZ->AddPoint(2,$z);
$aCSplineX->AddPoint(2,$x);
$aCSplineY->AddPoint(2,$y);
$aCSplineZ->AddPoint(2,$z);
$inputPoints->InsertPoint(2,$x,$y,$z);
$x = -1.0;
$y = 1.0;
$z = 0.0;
$aKSplineX->AddPoint(3,$x);
$aKSplineY->AddPoint(3,$y);
$aKSplineZ->AddPoint(3,$z);
$aCSplineX->AddPoint(3,$x);
$aCSplineY->AddPoint(3,$y);
$aCSplineZ->AddPoint(3,$z);
$inputPoints->InsertPoint(3,$x,$y,$z);
$inputData = Graphics::VTK::PolyData->new;
$inputData->SetPoints($inputPoints);
$balls = Graphics::VTK::SphereSource->new;
$balls->SetRadius('.04');
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
$Kpoints = Graphics::VTK::Points->new;
$Cpoints = Graphics::VTK::Points->new;
$profileKData = Graphics::VTK::PolyData->new;
$profileCData = Graphics::VTK::PolyData->new;
$numberOfInputPoints = 5;
$numberOfOutputPoints = 100;
$offset = 1.0;
#
sub fit
{
 my $i;
 my $t;
 # Global Variables Declared for this function: numberOfInputPoints, numberOfOutputPoints, offset
 $Kpoints->Reset;
 $Cpoints->Reset;
 for ($i = 0; $i < $numberOfOutputPoints; $i += 1)
  {
   $t = ($numberOfInputPoints - $offset) / ($numberOfOutputPoints - 1) * $i;
   $Kpoints->InsertPoint($i,$aKSplineX->Evaluate($t),$aKSplineY->Evaluate($t),$aKSplineZ->Evaluate($t));
   $Cpoints->InsertPoint($i,$aCSplineX->Evaluate($t),$aCSplineY->Evaluate($t),$aCSplineZ->Evaluate($t));
  }
 $profileKData->Modified;
 $profileCData->Modified;
}
fit();
$lines = Graphics::VTK::CellArray->new;
$lines->InsertNextCell($numberOfOutputPoints);
for ($i = 0; $i < $numberOfOutputPoints; $i += 1)
 {
  $lines->InsertCellPoint($i);
 }
$profileKData->SetPoints($Kpoints);
$profileKData->SetLines($lines);
$profileCData->SetPoints($Cpoints);
$profileCData->SetLines($lines);
$profileKTubes = Graphics::VTK::TubeFilter->new;
$profileKTubes->SetNumberOfSides(8);
$profileKTubes->SetInput($profileKData);
$profileKTubes->SetRadius('.01');
$profileKMapper = Graphics::VTK::PolyDataMapper->new;
$profileKMapper->SetInput($profileKTubes->GetOutput);
$profileK = Graphics::VTK::Actor->new;
$profileK->SetMapper($profileKMapper);
$profileK->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::banana);
$profileK->GetProperty->SetSpecular('.3');
$profileK->GetProperty->SetSpecularPower(30);
$ren1->AddActor($profileK);
$profileCTubes = Graphics::VTK::TubeFilter->new;
$profileCTubes->SetNumberOfSides(8);
$profileCTubes->SetInput($profileCData);
$profileCTubes->SetRadius('.01');
$profileCMapper = Graphics::VTK::PolyDataMapper->new;
$profileCMapper->SetInput($profileCTubes->GetOutput);
$profileC = Graphics::VTK::Actor->new;
$profileC->SetMapper($profileCMapper);
$profileC->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::peacock);
$profileC->GetProperty->SetSpecular('.3');
$profileC->GetProperty->SetSpecularPower(30);
$ren1->AddActor($profileC);
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
 my $aSplineX;
 my $aSplineY;
 my $aSplineZ;
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
 my $aSplineX;
 my $aSplineY;
 my $aSplineZ;
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
 my $aSplineX;
 my $aSplineY;
 my $aSplineZ;
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
 my $aSplineX;
 my $aSplineY;
 my $aSplineZ;
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
 my $aSplineX;
 my $aSplineY;
 my $aSplineZ;
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
 my $aSplineX;
 my $aSplineY;
 my $aSplineZ;
 my $fit;
 # Global Variables Declared for this function: offset
 $offset = 1.0;
 $aSplineX->ClosedOff;
 $aSplineY->ClosedOff;
 $aSplineZ->ClosedOff;
 fit();
 $renWin->Render;
}
$renWin->SetFileName('closedSplines.tcl.ppm');
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
