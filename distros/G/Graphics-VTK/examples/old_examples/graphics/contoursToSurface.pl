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
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Create the data
$points = Graphics::VTK::Points->new;
$polys = Graphics::VTK::CellArray->new;
$i = 0;
for ($z = -5; $z < 30; $z += 1)
 {
  for ($xtraX = 0; $xtraX < 90; $xtraX += 30)
   {
    for ($xtraY = 0; $xtraY < 90; $xtraY += 30)
     {
      $x = -10;
      $y = -10;
      $x = $x + $xtraX;
      $y = $y + $xtraY;
      $x += 1 if ($z % 12 == 0);
      $x += 2 if ($z % 12 == 1);
      $x += 3 if ($z % 12 == 2);
      if ($z % 12 == 3)
       {
        $x += 3;
        $y += 1;
       }
      if ($z % 12 == 4)
       {
        $x += 3;
        $y += 2;
       }
      if ($z % 12 == 5)
       {
        $x += 3;
        $y += 3;
       }
      if ($z % 12 == 6)
       {
        $x += 2;
        $y += 3;
       }
      if ($z % 12 == 7)
       {
        $x += 1;
        $y += 3;
       }
      $y += 3 if ($z % 12 == 8);
      $y += 2 if ($z % 12 == 9);
      $y += 1 if ($z % 12 == 10);
      unless ((($xtraX == 30 || $xtraY == 30) && ($xtraX != $xtraY)))
       {
        $polys->InsertNextCell(4);
        $points->InsertPoint($i,$x + 0,$y + 0,$z);
        $polys->InsertCellPoint($i);
        $i += 1;
        $points->InsertPoint($i,$x + 20,$y + 0,$z);
        $polys->InsertCellPoint($i);
        $i += 1;
        $points->InsertPoint($i,$x + 20,$y + 20,$z);
        $polys->InsertCellPoint($i);
        $i += 1;
        $points->InsertPoint($i,$x + 0,$y + 20,$z);
        $polys->InsertCellPoint($i);
        $i += 1;
        $polys->InsertNextCell(4);
        $points->InsertPoint($i,$x + 4,$y + 4,$z);
        $polys->InsertCellPoint($i);
        $i += 1;
        $points->InsertPoint($i,$x + 16,$y + 4,$z);
        $polys->InsertCellPoint($i);
        $i += 1;
        $points->InsertPoint($i,$x + 16,$y + 16,$z);
        $polys->InsertCellPoint($i);
        $i += 1;
        $points->InsertPoint($i,$x + 4,$y + 16,$z);
        $polys->InsertCellPoint($i);
        $i += 1;
       }
      if ($xtraX != 30 || $xtraY != 30)
       {
        $polys->InsertNextCell(4);
        $points->InsertPoint($i,$x + 8,$y + 8,$z);
        $polys->InsertCellPoint($i);
        $i += 1;
        $points->InsertPoint($i,$x + 12,$y + 8,$z);
        $polys->InsertCellPoint($i);
        $i += 1;
        $points->InsertPoint($i,$x + 12,$y + 12,$z);
        $polys->InsertCellPoint($i);
        $i += 1;
        $points->InsertPoint($i,$x + 8,$y + 12,$z);
        $polys->InsertCellPoint($i);
        $i += 1;
       }
     }
   }
 }
# Create a representation of the contours used as input
$contours = Graphics::VTK::PolyData->new;
$contours->SetPoints($points);
$contours->SetPolys($polys);
$contourMapper = Graphics::VTK::PolyDataMapper->new;
$contourMapper->SetInput($contours);
$contourActor = Graphics::VTK::Actor->new;
$contourActor->SetMapper($contourMapper);
$contourActor->GetProperty->SetColor(1,0,0);
$contourActor->GetProperty->SetAmbient(1);
$contourActor->GetProperty->SetDiffuse(0);
$contourActor->GetProperty->SetRepresentationToWireframe;
$ren1->AddProp($contourActor);
$ren1->GetActiveCamera->Azimuth(10);
$ren1->GetActiveCamera->Elevation(30);
$ren1->ResetCameraClippingRange;
$renWin->SetSize(500,500);
$renWin->Render;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
# Create the contour to surface filter
$f = Graphics::VTK::VoxelContoursToSurfaceFilter->new;
$f->SetInput($contours);
$f->SetMemoryLimitInBytes(100000);
$m = Graphics::VTK::PolyDataMapper->new;
$m->SetInput($f->GetOutput);
$m->ScalarVisibilityOff;
$m->ImmediateModeRenderingOn;
$a = Graphics::VTK::Actor->new;
$a->SetMapper($m);
$ren1->AddProp($a);
$contourActor->VisibilityOff;
$ren1->SetBackground('.1','.2','.4');
$renWin->Render;
#renWin SetFileName "contoursToSurface.tcl.ppm"
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
