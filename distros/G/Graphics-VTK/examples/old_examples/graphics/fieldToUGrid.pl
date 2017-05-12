#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Read a field representing unstructured grid and display it (similar to blow.tcl)
use Graphics::VTK::Tk::vtkInt;
# create a reader and write out field daya
$reader = Graphics::VTK::UnstructuredGridReader->new;
$reader->SetFileName("$VTK_DATA/blow.vtk");
$reader->SetScalarsName("thickness9");
$reader->SetVectorsName("displacement9");
$ds2do = Graphics::VTK::DataSetToDataObjectFilter->new;
$ds2do->SetInput($reader->GetOutput);
$write = Graphics::VTK::DataObjectWriter->new;
$write->SetInput($ds2do->GetOutput);
$write->SetFileName("UGridField.vtk");
$write->Write;
# Read the field and convert to unstructured grid.
$dor = Graphics::VTK::DataObjectReader->new;
$dor->SetFileName("UGridField.vtk");
$do2ds = Graphics::VTK::DataObjectToDataSetFilter->new;
$do2ds->SetInput($dor->GetOutput);
$do2ds->SetDataSetTypeToUnstructuredGrid;
$do2ds->SetPointComponent(0,'Points',0);
$do2ds->SetPointComponent(1,'Points',1);
$do2ds->SetPointComponent(2,'Points',2);
$do2ds->SetCellTypeComponent('CellTypes',0);
$do2ds->SetCellConnectivityComponent('Cells',0);
$fd2ad = Graphics::VTK::FieldDataToAttributeDataFilter->new;
$fd2ad->SetInput($do2ds->GetUnstructuredGridOutput);
$fd2ad->SetInputFieldToDataObjectField;
$fd2ad->SetOutputAttributeDataToPointData;
$fd2ad->SetVectorComponent(0,'PointVectors',0);
$fd2ad->SetVectorComponent(1,'PointVectors',1);
$fd2ad->SetVectorComponent(2,'PointVectors',2);
$fd2ad->SetScalarComponent(0,'PointScalars',0);
# Now start visualizing
$warp = Graphics::VTK::WarpVector->new;
$warp->SetInput($fd2ad->GetUnstructuredGridOutput);
# extract mold from mesh using connectivity
$connect = Graphics::VTK::ConnectivityFilter->new;
$connect->SetInput($warp->GetOutput);
$connect->SetExtractionModeToSpecifiedRegions;
$connect->AddSpecifiedRegion(0);
$connect->AddSpecifiedRegion(1);
$moldMapper = Graphics::VTK::DataSetMapper->new;
$moldMapper->SetInput($connect->GetOutput);
$moldMapper->ScalarVisibilityOff;
$moldActor = Graphics::VTK::Actor->new;
$moldActor->SetMapper($moldMapper);
$moldActor->GetProperty->SetColor('.2','.2','.2');
$moldActor->GetProperty->SetRepresentationToWireframe;
# extract parison from mesh using connectivity
$connect2 = Graphics::VTK::ConnectivityFilter->new;
$connect2->SetInput($warp->GetOutput);
$connect2->SetExtractionModeToSpecifiedRegions;
$connect2->AddSpecifiedRegion(2);
$parison = Graphics::VTK::GeometryFilter->new;
$parison->SetInput($connect2->GetOutput);
$normals2 = Graphics::VTK::PolyDataNormals->new;
$normals2->SetInput($parison->GetOutput);
$normals2->SetFeatureAngle(60);
$lut = Graphics::VTK::LookupTable->new;
$lut->SetHueRange(0.0,0.66667);
$parisonMapper = Graphics::VTK::PolyDataMapper->new;
$parisonMapper->SetInput($normals2->GetOutput);
$parisonMapper->SetLookupTable($lut);
$parisonMapper->SetScalarRange(0.12,1.0);
$parisonActor = Graphics::VTK::Actor->new;
$parisonActor->SetMapper($parisonMapper);
$cf = Graphics::VTK::ContourFilter->new;
$cf->SetInput($connect2->GetOutput);
$cf->SetValue(0,'.5');
$contourMapper = Graphics::VTK::PolyDataMapper->new;
$contourMapper->SetInput($cf->GetOutput);
$contours = Graphics::VTK::Actor->new;
$contours->SetMapper($contourMapper);
# Create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($moldActor);
$ren1->AddActor($parisonActor);
$ren1->AddActor($contours);
$ren1->GetActiveCamera->Azimuth(60);
$ren1->GetActiveCamera->Roll(-90);
$ren1->GetActiveCamera->Dolly(2);
$ren1->ResetCameraClippingRange;
$ren1->SetBackground(1,1,1);
$renWin->SetSize(750,400);
$iren->Initialize;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->SetFileName("fieldToUGrid.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
