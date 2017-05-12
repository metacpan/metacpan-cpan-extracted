#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Regression test coutesy of Paul Hsieh, pashieh@usgs.gov
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the rendering stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Create scalars for cells
$scalars = Graphics::VTK::Scalars->new;
$scalars->SetNumberOfScalars(20 * 20 * 20);
$n = 0;
for ($k = 0; $k < 20; $k += 1)
 {
  $z = 0.1 * ($k - 10);
  for ($j = 0; $j < 20; $j += 1)
   {
    $y = 0.1 * ($j - 10) + '.05';
    for ($i = 0; $i < 20; $i += 1)
     {
      $x = 0.1 * ($i - 10) + '.05';
      $s = sqrt($x * $x + $y * $y + $z * $z);
      $scalars->SetScalar($n,$s);
      $n += 1;
     }
   }
 }
# Create the structured grid
$spoints = Graphics::VTK::StructuredPoints->new;
$spoints->SetDimensions(21,21,21);
$spoints->SetOrigin(-10,-10,-10);
$spoints->SetSpacing('.1','.1','.1');
$spoints->GetCellData->SetScalars($scalars);
# Create the mapper and actor for the structrued grid
$spointsMapper = Graphics::VTK::DataSetMapper->new;
$spointsMapper->SetInput($spoints);
$spointsMapper->SetScalarRange(0.6,1.6);
$spointsActor = Graphics::VTK::Actor->new;
$spointsActor->SetMapper($spointsMapper);
$ren1->AddActor($spointsActor);
# Extract 3 sides of the structured grid
$geom1 = Graphics::VTK::StructuredPointsGeometryFilter->new;
$geom1->SetInput($spoints);
$geom1->SetExtent(20,20,0,20,0,20);
$geom1Mapper = Graphics::VTK::PolyDataMapper->new;
$geom1Mapper->SetInput($geom1->GetOutput);
$geom1Mapper->SetScalarRange(0.6,1.6);
$geom1Actor = Graphics::VTK::Actor->new;
$geom1Actor->SetMapper($geom1Mapper);
$geom1Actor->AddPosition(2.5,0,0);
$ren1->AddActor($geom1Actor);
$geom2 = Graphics::VTK::StructuredPointsGeometryFilter->new;
$geom2->SetInput($spoints);
$geom2->SetExtent(0,20,0,20,20,20);
$geom2Mapper = Graphics::VTK::PolyDataMapper->new;
$geom2Mapper->SetInput($geom2->GetOutput);
$geom2Mapper->SetScalarRange(0.6,1.6);
$geom2Actor = Graphics::VTK::Actor->new;
$geom2Actor->SetMapper($geom2Mapper);
$geom2Actor->AddPosition(2.5,0,0);
$ren1->AddActor($geom2Actor);
$geom3 = Graphics::VTK::StructuredPointsGeometryFilter->new;
$geom3->SetInput($spoints);
$geom3->SetExtent(0,20,20,20,0,20);
$geom3Mapper = Graphics::VTK::PolyDataMapper->new;
$geom3Mapper->SetInput($geom3->GetOutput);
$geom3Mapper->SetScalarRange(0.6,1.6);
$geom3Actor = Graphics::VTK::Actor->new;
$geom3Actor->SetMapper($geom3Mapper);
$geom3Actor->AddPosition(2.5,0,0);
$ren1->AddActor($geom3Actor);
$renWin->SetSize(300,300);
$ren1->GetActiveCamera->Azimuth(30);
$ren1->GetActiveCamera->Elevation(40);
$ren1->GetActiveCamera->Dolly(1.25);
$ren1->ResetCameraClippingRange;
$renWin->Render;
$iren->Initialize;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
#renWin SetFileName "StructuredPointsExtents.tcl.ppm"
#renWin SaveImageAsPPM
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
