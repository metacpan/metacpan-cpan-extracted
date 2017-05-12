#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Demonstrate the generation of a structured grid from field data. The output
# should be similar to combIso.tcl.
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create a reader and write out the field
$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA/combxyz.bin");
$pl3d->SetQFileName("$VTK_DATA/combq.bin");
$ds2do = Graphics::VTK::DataSetToDataObjectFilter->new;
$ds2do->SetInput($pl3d->GetOutput);
$writer = Graphics::VTK::DataObjectWriter->new;
$writer->SetInput($ds2do->GetOutput);
$writer->SetFileName("SGridField.vtk");
$writer->Write;
# read the field
$dor = Graphics::VTK::DataObjectReader->new;
$dor->SetFileName("SGridField.vtk");
$do2ds = Graphics::VTK::DataObjectToDataSetFilter->new;
$do2ds->SetInput($dor->GetOutput);
$do2ds->SetDataSetTypeToStructuredGrid;
$do2ds->SetDimensionsComponent('Dimensions',0);
$do2ds->SetPointComponent(0,'Points',0);
$do2ds->SetPointComponent(1,'Points',1);
$do2ds->SetPointComponent(2,'Points',2);
$fd2ad = Graphics::VTK::FieldDataToAttributeDataFilter->new;
$fd2ad->SetInput($do2ds->GetStructuredGridOutput);
$fd2ad->SetInputFieldToDataObjectField;
$fd2ad->SetOutputAttributeDataToPointData;
$fd2ad->SetVectorComponent(0,'PointVectors',0);
$fd2ad->SetVectorComponent(1,'PointVectors',1);
$fd2ad->SetVectorComponent(2,'PointVectors',2);
$fd2ad->SetScalarComponent(0,'PointScalars',0);
# create pipeline
$iso = Graphics::VTK::ContourFilter->new;
$iso->SetInput($fd2ad->GetOutput);
$iso->SetValue(0,'.38');
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($iso->GetOutput);
$normals->SetFeatureAngle(45);
$isoMapper = Graphics::VTK::PolyDataMapper->new;
$isoMapper->SetInput($normals->GetOutput);
$isoMapper->ScalarVisibilityOff;
$isoActor = Graphics::VTK::Actor->new;
$isoActor->SetMapper($isoMapper);
$isoActor->GetProperty->SetColor(@Graphics::VTK::Colors::bisque);
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($fd2ad->GetStructuredGridOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($isoActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$ren1->SetBackground(0.1,0.2,0.4);
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(3.95297,50);
$cam1->SetFocalPoint(9.71821,0.458166,29.3999);
$cam1->SetPosition(2.7439,-37.3196,38.7167);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(-0.16123,0.264271,0.950876);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
$renWin->SetFileName("fieldToSGrid.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
