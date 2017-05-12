#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Demonstrate the separation of datasets (i.e., topology/geometry) from
# attribute data (i.e., a field) into different files.
use Graphics::VTK::Tk::vtkInt;
# create readers
$readGeom = Graphics::VTK::UnstructuredGridReader->new;
$readGeom->SetFileName("$VTK_DATA/blowGeom.vtk");
$readAttr = Graphics::VTK::DataObjectReader->new;
$readAttr->SetFileName("$VTK_DATA/blowAttr.vtk");
$readAttr->SetFieldDataName("time9");
# combine data and build scalars and vectors
$merge = Graphics::VTK::MergeDataObjectFilter->new;
$merge->SetInput($readGeom->GetOutput);
$merge->SetDataObject($readAttr->GetOutput);
$fd2ad = Graphics::VTK::FieldDataToAttributeDataFilter->new;
$fd2ad->SetInput($merge->GetOutput);
$fd2ad->SetOutputAttributeDataToPointData;
$fd2ad->SetVectorComponent(0,'displacement',0);
$fd2ad->SetVectorComponent(1,'displacement',1);
$fd2ad->SetVectorComponent(2,'displacement',2);
$fd2ad->SetScalarComponent(0,'thickness',0);
# warp data with vectors
$warp = Graphics::VTK::WarpVector->new;
$warp->SetInput($fd2ad->GetUnstructuredGridOutput);
# extract mold from mesh using connectivity
$connect = Graphics::VTK::ConnectivityFilter->new;
$connect->SetInput($warp->GetOutput);
$connect->SetExtractionModeToSpecifiedRegions;
$connect->AddSpecifiedRegion(0);
$connect->AddSpecifiedRegion(1);
$moldMapper = Graphics::VTK::DataSetMapper->new;
$moldMapper->SetInput($readGeom->GetOutput);
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
$renWin->SetFileName("mergeDataObject.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
