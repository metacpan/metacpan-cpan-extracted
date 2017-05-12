#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Color points with scalars
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create some points with scalars
$chars = Graphics::VTK::UnsignedCharArray->new;
$chars->SetNumberOfComponents(3);
$chars->SetNumberOfTuples(3);
$chars->InsertComponent(0,0,255);
$chars->InsertComponent(0,1,99);
$chars->InsertComponent(0,2,71);
$chars->InsertComponent(1,0,125);
$chars->InsertComponent(1,1,255);
$chars->InsertComponent(1,2,0);
$chars->InsertComponent(2,0,226);
$chars->InsertComponent(2,1,207);
$chars->InsertComponent(2,2,87);
$scalars = Graphics::VTK::Scalars->new;
$scalars->SetData($chars);
$polyVertexPoints = Graphics::VTK::Points->new;
$polyVertexPoints->SetNumberOfPoints(3);
$polyVertexPoints->InsertPoint(0,0,0,0);
$polyVertexPoints->InsertPoint(1,1,0,0);
$polyVertexPoints->InsertPoint(2,1,1,0);
$aPolyVertex = Graphics::VTK::PolyVertex->new;
$aPolyVertex->GetPointIds->SetNumberOfIds(3);
$aPolyVertex->GetPointIds->SetId(0,0);
$aPolyVertex->GetPointIds->SetId(1,1);
$aPolyVertex->GetPointIds->SetId(2,2);
$aPolyVertexGrid = Graphics::VTK::UnstructuredGrid->new;
$aPolyVertexGrid->Allocate(1,1);
$aPolyVertexGrid->InsertNextCell($aPolyVertex->GetCellType,$aPolyVertex->GetPointIds);
$aPolyVertexGrid->SetPoints($polyVertexPoints);
$aPolyVertexGrid->GetPointData->SetScalars($scalars);
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetRadius('.1');
$glyphs = Graphics::VTK::Glyph3D->new;
$glyphs->ScalingOff;
$glyphs->SetColorModeToColorByScalar;
$glyphs->SetScaleModeToDataScalingOff;
$glyphs->SetInput($aPolyVertexGrid);
$glyphs->SetSource($sphere->GetOutput);
$glyphsMapper = Graphics::VTK::DataSetMapper->new;
$glyphsMapper->SetInput($glyphs->GetOutput);
$glyphsActor = Graphics::VTK::Actor->new;
$glyphsActor->SetMapper($glyphsMapper);
$glyphsActor->GetProperty->BackfaceCullingOn;
$ren1->SetBackground('.1','.2','.4');
$ren1->AddActor('glyphsActor');
$glyphsActor->GetProperty->SetDiffuseColor(1,1,1);
$ren1->GetActiveCamera->Azimuth(30);
$ren1->GetActiveCamera->Elevation(20);
$ren1->GetActiveCamera->Dolly(1.25);
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
#renWin SetFileName "scalarColors.tcl.ppm"
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
