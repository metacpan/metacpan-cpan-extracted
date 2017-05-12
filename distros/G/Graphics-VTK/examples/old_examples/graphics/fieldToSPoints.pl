#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
## Demonstrates conversion of field data into structured points
# Output should be the same as complexV.tcl.
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create a reader and write out the field
$reader = Graphics::VTK::StructuredPointsReader->new;
$reader->SetFileName("$VTK_DATA/carotid.vtk");
$ds2do = Graphics::VTK::DataSetToDataObjectFilter->new;
$ds2do->SetInput($reader->GetOutput);
$writer = Graphics::VTK::DataObjectWriter->new;
$writer->SetInput($ds2do->GetOutput);
$writer->SetFileName("SPtsField.vtk");
$writer->Write;
# create pipeline
# read the field
$dor = Graphics::VTK::DataObjectReader->new;
$dor->SetFileName("SPtsField.vtk");
$do2ds = Graphics::VTK::DataObjectToDataSetFilter->new;
$do2ds->SetInput($dor->GetOutput);
$do2ds->SetDataSetTypeToStructuredPoints;
$do2ds->SetDimensionsComponent('Dimensions',0);
$do2ds->SetOriginComponent('Origin',0);
$do2ds->SetSpacingComponent('Spacing',0);
$fd2ad = Graphics::VTK::FieldDataToAttributeDataFilter->new;
$fd2ad->SetInput($do2ds->GetStructuredPointsOutput);
$fd2ad->SetInputFieldToDataObjectField;
$fd2ad->SetOutputAttributeDataToPointData;
$fd2ad->SetVectorComponent(0,'PointVectors',0);
$fd2ad->SetVectorComponent(1,'PointVectors',1);
$fd2ad->SetVectorComponent(2,'PointVectors',2);
$fd2ad->SetScalarComponent(0,'PointScalars',0);
$hhog = Graphics::VTK::HedgeHog->new;
$hhog->SetInput($fd2ad->GetOutput);
$hhog->SetScaleFactor(0.3);
$lut = Graphics::VTK::LookupTable->new;
#    lut SetHueRange .667 0.0
$lut->Build;
$hhogMapper = Graphics::VTK::PolyDataMapper->new;
$hhogMapper->SetInput($hhog->GetOutput);
$hhogMapper->SetScalarRange(50,550);
$hhogMapper->SetLookupTable($lut);
$hhogMapper->ImmediateModeRenderingOn;
$hhogActor = Graphics::VTK::Actor->new;
$hhogActor->SetMapper($hhogMapper);
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($fd2ad->GetOutput);
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
$ren1->AddActor($hhogActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$ren1->SetBackground(0.1,0.2,0.4);
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$ren1->GetActiveCamera->Zoom(1.5);
$renWin->Render;
$renWin->SetFileName("fieldToSPoints.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
