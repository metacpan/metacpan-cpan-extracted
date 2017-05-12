#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Generate geometry for Structured grid of each dimension
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$math = Graphics::VTK::Math->new;
# create a 0, 1, 2 and 3 dimensional Structured frid
$dimensions{0} = [ qw/1 1 1/ ];
$dimensions{1} = [ qw/13 1 1/ ];
$dimensions{2} = [ qw/13 11 1/ ];
$dimensions{3} = [ qw/13 11 11/ ];
$dims = [ qw/0 1 2 3/ ];
$array{0} = 'vtkFloatArray';
$array{1} = 'vtkDoubleArray';
$array{2} = 'vtkFloatArray';
$array{3} = 'vtkDoubleArray';
foreach $dim (@$dims)
 {
  $numTuples = $dimensions{$dim}[0] * $dimensions{$dim}[1] * $dimensions{$dim}[2];
  $points{$dim} = Graphics::VTK::Points->new;
  $points{$dim}->SetNumberOfPoints($numTuples);
  $rMin = 0.5;
  $rMax = 1.0;
  $deltaZ = 0.0;
  eval
   {
    $deltaZ = 2.0 / ($dimensions{$dim}[2] - 1);
   }
  ;
  $deltaRad = 0.0;
  eval
   {
    $deltaRad = ($rMax - $rMin) / ($dimensions{$dim}[1] - 1);
   }
  ;
  for ($k = 0; $k < $dimensions{$dim}[2]; $k += 1)
   {
    $xyz{2} = -1.0 + $k * $deltaZ;
    $kOffset = $k * $dimensions{$dim}[0] * $dimensions{$dim}[1];
    for ($j = 0; $j < $dimensions{$dim}[1]; $j += 1)
     {
      $radius = $rMin + $j * $deltaRad;
      $jOffset = $j * $dimensions{$dim}[0];
      for ($i = 0; $i < $dimensions{$dim}[0]; $i += 1)
       {
        $theta = $i * 15.0 * $math->DegreesToRadians;
        $xyz{0} = $radius * cos($theta);
        $xyz{1} = $radius * sin($theta);
        $offset = $i + $jOffset + $kOffset;
        $points{$dim}->InsertPoint($offset,$xyz{0},$xyz{1},$xyz{2});
       }
     }
   }
  # build an array of scalar values
  $da{$dim} = "Graphics::VTK::$array{$dim}"->new;
  $da{$dim}->SetNumberOfTuples($numTuples);
  for ($i = 0; $i < $numTuples; $i += 1)
   {
    $da{$dim}->InsertComponent($i,0,$math->Random(0,127));
   }
  $s{$dim} = Graphics::VTK::Scalars->new;
  $s{$dim}->SetData($da{$dim});
  # define the structured grid
  $sg{$dim} = Graphics::VTK::StructuredGrid->new;
  $sg{$dim}->SetDimensions($dimensions{$dim});
  $sg{$dim}->GetCellData->SetScalars($s{$dim});
  $sg{$dim}->SetPoints($points{$dim});
  $sggf{$dim} = Graphics::VTK::StructuredGridGeometryFilter->new;
  $sggf{$dim}->SetInput($sg{$dim});
  $pdm{$dim} = Graphics::VTK::PolyDataMapper->new;
  $pdm{$dim}->SetInput($sggf{$dim}->GetOutput);
  $pdm{$dim}->SetScalarRange(0,127);
  $actor{$dim} = Graphics::VTK::Actor->new;
  $actor{$dim}->SetMapper($pdm{$dim});
  $actor{$dim}->AddPosition(2.0 * $dim,0,0);
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
$renWin->SetFileName("StructuredGridGeometry.tcl.ppm");
#renWin SaveImageAsPPM
$writer = Graphics::VTK::DataSetWriter->new;
$writer->SetFileName('sgrid.vtk');
$writer->SetInput('sg3');
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
