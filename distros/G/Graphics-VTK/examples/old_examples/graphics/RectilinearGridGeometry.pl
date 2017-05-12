#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Generate geometry for rectilinear grid of each dimension
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$math = Graphics::VTK::Math->new;
# create a 0, 1, 2 and 3 dimensional rectilinear frid
$sxArray0 = Graphics::VTK::FloatArray->new;
$sxArray0->InsertNextValue(0);
$syArray0 = Graphics::VTK::FloatArray->new;
$syArray0->InsertNextValue(0);
$szArray0 = Graphics::VTK::FloatArray->new;
$szArray0->InsertNextValue(0);
$sxArray1 = Graphics::VTK::FloatArray->new;
$j = 0;
for ($i = 0; $i < 10; $i += 1)
 {
  $sxArray1->InsertNextValue($j);
  $j = $j + $i + 1;
 }
$syArray1 = Graphics::VTK::FloatArray->new;
$syArray1->InsertNextValue(0);
$szArray1 = Graphics::VTK::FloatArray->new;
$szArray1->InsertNextValue(0);
$sxArray2 = Graphics::VTK::FloatArray->new;
$j = 0;
for ($i = 0; $i < 10; $i += 1)
 {
  $sxArray2->InsertNextValue($j);
  $j = $j + $i + 1;
 }
$syArray2 = Graphics::VTK::FloatArray->new;
$j = 0;
for ($i = 0; $i < 10; $i += 1)
 {
  $syArray2->InsertNextValue($j);
  $j = $j + $i + 1;
 }
$szArray2 = Graphics::VTK::FloatArray->new;
$szArray2->InsertNextValue(0);
$sxArray3 = Graphics::VTK::FloatArray->new;
$j = 0;
for ($i = 0; $i < 10; $i += 1)
 {
  $sxArray3->InsertNextValue($j);
  $j = $j + $i + 1;
 }
$syArray3 = Graphics::VTK::FloatArray->new;
$j = 0;
for ($i = 0; $i < 10; $i += 1)
 {
  $syArray3->InsertNextValue($j);
  $j = $j + $i + 1;
 }
$szArray3 = Graphics::VTK::FloatArray->new;
$j = 0;
for ($i = 0; $i < 10; $i += 1)
 {
  $szArray3->InsertNextValue($j);
  $j = $j + $i + 1;
 }
$dimensions{0} = "1 1 1";
$dimensions{1} = "10 1 1";
$dimensions{2} = "10 10 1";
$dimensions{3} = "10 10 10";
$dims = "0 1 2 3";
$array{0} = 'vtkUnsignedCharArray';
$array{1} = 'vtkUnsignedShortArray';
$array{2} = 'vtkUnsignedLongArray';
$array{3} = 'vtkFloatArray';
foreach $dim ($dims)
 {
  $numTuples = $dimensions{$dim}[0] * $dimensions{$dim}[1] * $dimensions{$dim}[2];
  $array{$dim}->$da{$dim};
  $da{$dim}->SetNumberOfTuples($numTuples);
  for ($i = 0; $i < $numTuples; $i += 1)
   {
    $da{$dim}->InsertComponent($i,0,$math->Random(0,127));
   }
  $s{$dim} = Graphics::VTK::Scalars->new;
  $s{$dim}->SetData($da{$dim});
  $sx{$dim} = Graphics::VTK::Scalars->new;
  $sx{$dim}->SetData($sxArray{$dim});
  $sy{$dim} = Graphics::VTK::Scalars->new;
  $sy{$dim}->SetData($syArray{$dim});
  $sz{$dim} = Graphics::VTK::Scalars->new;
  $sz{$dim}->SetData($szArray{$dim});
  $rg{$dim} = Graphics::VTK::RectilinearGrid->new;
  $rg{$dim}->SetDimensions($dimensions{$dim});
  $rg{$dim}->GetCellData->SetScalars($s{$dim});
  $rg{$dim}->SetXCoordinates($sx{$dim});
  $rg{$dim}->SetYCoordinates($sy{$dim});
  $rg{$dim}->SetZCoordinates($sz{$dim});
  $rggf{$dim} = Graphics::VTK::RectilinearGridGeometryFilter->new;
  $rggf{$dim}->SetInput($rg{$dim});
  $pdm{$dim} = Graphics::VTK::PolyDataMapper->new;
  $pdm{$dim}->SetInput($rggf{$dim}->GetOutput);
  $pdm{$dim}->SetScalarRange(0,127);
  $actor{$dim} = Graphics::VTK::Actor->new;
  $actor{$dim}->SetMapper($pdm{$dim});
  $actor{$dim}->AddPosition(50 * $dim,0,0);
  $ren1->AddActor($actor{$dim});
 }
$ren1->SetBackground(0.2,0.2,0.2);
$renWin->SetSize(300,150);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$cam1 = $ren1->GetActiveCamera;
$cam1->Azimuth(-30);
$cam1->Elevation(30);
$cam1->Zoom(2.5);
$ren1->ResetCameraClippingRange;
$renWin->Render;
#renWin SetFileName "RectilinearGridGeometry.tcl.ppm"
#renWin SaveImageAsPPM
$writer = Graphics::VTK::DataSetWriter->new;
$writer->SetFileName('rgrid.vtk');
$writer->SetInput('rg3');
$writer->Update;
#
sub TkCheckAbort
{
 my $foo;
 $foo = $renWin->GetEventPending;
 $renWin->SetAbortRender(1) if ($foo != 0);
}
$renWin->SetAbortCheckMethod(
 sub
  {
   TkCheckAbort();
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
