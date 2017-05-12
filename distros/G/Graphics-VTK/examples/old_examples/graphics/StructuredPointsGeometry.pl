#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Generate geometry for structured points of each dimension
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$math = Graphics::VTK::Math->new;
# create a 0, 1, 2 and 3 dimensional structured points
$dimensions{0} = [ qw/1 1 1/ ];
$dimensions{1} = [ qw/10 1 1/ ];
$dimensions{2} = [ qw/10 10 1/ ];
$dimensions{3} = [ qw/10 10 10/ ];
$dims = [ qw/0 1 2 3/ ];
$array{0} = 'vtkUnsignedCharArray';
$array{1} = 'vtkShortArray';
$array{2} = 'vtkLongArray';
$array{3} = 'vtkDoubleArray';
foreach $dim (@$dims)
 {
  $numTuples = $dimensions{$dim}[0] * $dimensions{$dim}[1] * $dimensions{$dim}[2];
  $da{$dim} = "Graphics::VTK::$array{$dim}"->new;
  $da{$dim}->SetNumberOfTuples($numTuples);
  for ($i = 0; $i < $numTuples; $i += 1)
   {
    $da{$dim}->InsertComponent($i,0,$math->Random(-100,100));
   }
  $s{$dim} = Graphics::VTK::Scalars->new;
  $s{$dim}->SetData($da{$dim});
  $sp{$dim} = Graphics::VTK::StructuredPoints->new;
  $sp{$dim}->SetDimensions($dimensions{$dim});
  $sp{$dim}->GetCellData->SetScalars($s{$dim});
  $spgf{$dim} = Graphics::VTK::StructuredPointsGeometryFilter->new;
  $spgf{$dim}->SetInput($sp{$dim});
  $pdm{$dim} = Graphics::VTK::PolyDataMapper->new;
  $pdm{$dim}->SetInput($spgf{$dim}->GetOutput);
  $pdm{$dim}->SetScalarRange(-100,100);
  $actor{$dim} = Graphics::VTK::Actor->new;
  $actor{$dim}->SetMapper($pdm{$dim});
  $actor{$dim}->SetPosition($dim * 10,0,0);
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
#renWin SetFileName "StructuredPointsGeometry.tcl.ppm"
#renWin SaveImageAsPPM
$writer = Graphics::VTK::DataSetWriter->new;
$writer->SetFileName('sp.vtk');
$writer->SetInput('sp3');
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
