#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# test all polygon rendering
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$pnmReader = Graphics::VTK::PNMReader->new;
$pnmReader->SetFileName("$VTK_DATA/masonry.ppm");
$texture = Graphics::VTK::Texture->new;
$texture->SetInput($pnmReader->GetOutput);
$triangleStripPoints = Graphics::VTK::Points->new;
$triangleStripPoints->SetNumberOfPoints(5);
$triangleStripPoints->InsertPoint(0,0,1,0);
$triangleStripPoints->InsertPoint(1,0,0,'.5');
$triangleStripPoints->InsertPoint(2,1,1,'.3');
$triangleStripPoints->InsertPoint(3,1,0,'.6');
$triangleStripPoints->InsertPoint(4,2,1,'.1');
$triangleStripTCoords = Graphics::VTK::TCoords->new;
$triangleStripTCoords->SetNumberOfTCoords(5);
$triangleStripTCoords->InsertTCoord(0,0,1,0);
$triangleStripTCoords->InsertTCoord(1,0,0,0);
$triangleStripTCoords->InsertTCoord(2,'.5',1,0);
$triangleStripTCoords->InsertTCoord(3,'.5',0,0);
$triangleStripTCoords->InsertTCoord(4,1,1,0);
$triangleStripPointScalars = Graphics::VTK::Scalars->new;
$triangleStripPointScalars->SetNumberOfScalars(5);
$triangleStripPointScalars->InsertScalar(0,1);
$triangleStripPointScalars->InsertScalar(1,0);
$triangleStripPointScalars->InsertScalar(2,0);
$triangleStripPointScalars->InsertScalar(3,0);
$triangleStripPointScalars->InsertScalar(4,0);
$triangleStripCellScalars = Graphics::VTK::Scalars->new;
$triangleStripCellScalars->SetNumberOfScalars(1);
$triangleStripCellScalars->InsertScalar(0,1);
$triangleStripPointNormals = Graphics::VTK::Normals->new;
$triangleStripPointNormals->SetNumberOfNormals(5);
$triangleStripPointNormals->InsertNormal(0,0,0,1);
$triangleStripPointNormals->InsertNormal(1,0,1,0);
$triangleStripPointNormals->InsertNormal(2,0,1,1);
$triangleStripPointNormals->InsertNormal(3,1,0,0);
$triangleStripPointNormals->InsertNormal(4,1,0,1);
$triangleStripCellNormals = Graphics::VTK::Normals->new;
$triangleStripCellNormals->SetNumberOfNormals(1);
$triangleStripCellNormals->InsertNormal(0,1,1,1);
$aTriangleStrip = Graphics::VTK::TriangleStrip->new;
$aTriangleStrip->GetPointIds->SetNumberOfIds(5);
$aTriangleStrip->GetPointIds->SetId(0,0);
$aTriangleStrip->GetPointIds->SetId(1,1);
$aTriangleStrip->GetPointIds->SetId(2,2);
$aTriangleStrip->GetPointIds->SetId(3,3);
$aTriangleStrip->GetPointIds->SetId(4,4);
$lut = Graphics::VTK::LookupTable->new;
$lut->SetNumberOfColors(5);
$lut->SetTableValue(0,0,0,1,1);
$lut->SetTableValue(1,0,1,0,1);
$lut->SetTableValue(2,0,1,1,1);
$lut->SetTableValue(3,1,0,0,1);
$lut->SetTableValue(4,1,0,1,1);
$masks = "0 1 2 3 4 5 6 7 10 11 14 15 16 18 20 22 26 30";
$i = 0;
$j = 0;
$k = 0;
$types = "strip triangle";
foreach $type ($types)
 {
  foreach $mask ($masks)
   {
    $grid{$i} = Graphics::VTK::UnstructuredGrid->new;
    $grid{$i}->Allocate(1,1);
    $grid{$i}->InsertNextCell($aTriangleStrip->GetCellType,$aTriangleStrip->GetPointIds);
    $grid{$i}->SetPoints($triangleStripPoints);
    $geometry{$i} = Graphics::VTK::GeometryFilter->new;
    $geometry{$i}->SetInput($grid{$i});
    $triangles{$i} = Graphics::VTK::TriangleFilter->new;
    $triangles{$i}->SetInput($geometry{$i}->GetOutput);
    $mapper{$i} = Graphics::VTK::PolyDataMapper->new;
    $mapper{$i}->SetInput($geometry{$i}->GetOutput) if ($type eq "strip");
    $mapper{$i}->SetInput($triangles{$i}->GetOutput) if ($type eq "triangle");
    $mapper{$i}->SetLookupTable($lut);
    $mapper{$i}->SetScalarRange(0,4);
    $actor{$i} = Graphics::VTK::Actor->new;
    $actor{$i}->SetMapper($mapper{$i});
    $grid{$i}->GetPointData->SetNormals($triangleStripPointNormals) if (($mask & 1) != 0);
    if (($mask & 2) != 0)
     {
      $grid{$i}->GetPointData->SetScalars($triangleStripPointScalars);
      $mapper{$i}->SetScalarModeToUsePointData;
     }
    if (($mask & 4) != 0)
     {
      $grid{$i}->GetPointData->SetTCoords($triangleStripTCoords);
      $actor{$i}->SetTexture($texture);
     }
    if (($mask & 8) != 0)
     {
      $grid{$i}->GetCellData->SetScalars($triangleStripCellScalars);
      $mapper{$i}->SetScalarModeToUseCellData;
     }
    $grid{$i}->GetCellData->SetNormals($triangleStripCellNormals) if (($mask & 16) != 0);
    $actor{$i}->AddPosition($j * 2,$k * 2,0);
    $ren1->AddActor($actor{$i});
    $actor{$i}->GetProperty->SetRepresentationToWireframe;
    $j += 1;
    if ($j >= 6)
     {
      $j = 0;
      $k += 1;
     }
    $i += 1;
   }
 }
$renWin->SetSize(480,480);
$ren1->SetBackground('.7','.3','.1');
$ren1->GetActiveCamera->Dolly(1.5);
$ren1->ResetCameraClippingRange;
$renWin->Render;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$MW->withdraw;
#renWin SetFileName "PolyDataMapperAllWireframe.tcl.ppm"
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
