#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This example demonstrates the reading of a field and conversion to PolyData
# The output should be the same as polyEx.tcl.
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create a reader and write out the field
$reader = Graphics::VTK::PolyDataReader->new;
$reader->SetFileName("$VTK_DATA/polyEx.vtk");
$ds2do = Graphics::VTK::DataSetToDataObjectFilter->new;
$ds2do->SetInput($reader->GetOutput);
$writer = Graphics::VTK::DataObjectWriter->new;
$writer->SetInput($ds2do->GetOutput);
$writer->SetFileName("PolyField.vtk");
$writer->Write;
# create pipeline
$dor = Graphics::VTK::DataObjectReader->new;
$dor->SetFileName("PolyField.vtk");
$do2ds = Graphics::VTK::DataObjectToDataSetFilter->new;
$do2ds->SetInput($dor->GetOutput);
$do2ds->SetDataSetTypeToPolyData;
$do2ds->SetPointComponent(0,'Points',0);
$do2ds->SetPointComponent(1,'Points',1);
$do2ds->SetPointComponent(2,'Points',2);
$do2ds->SetPolysComponent('Polys',0);
$fd2ad = Graphics::VTK::FieldDataToAttributeDataFilter->new;
$fd2ad->SetInput($do2ds->GetPolyDataOutput);
$fd2ad->SetInputFieldToDataObjectField;
$fd2ad->SetOutputAttributeDataToPointData;
$fd2ad->SetScalarComponent(0,'PointScalars',0);
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($fd2ad->GetPolyDataOutput);
$mapper->SetScalarRange($fd2ad->GetOutput->GetScalarRange);
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($actor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(300,300);
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange('.348',17.43);
$cam1->SetPosition(2.92,2.62,-0.836);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(-0.436,-0.067,-0.897);
$cam1->Azimuth(90);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
$renWin->SetFileName("fieldToPolyData.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
