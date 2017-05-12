#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# Test the attribute to field data filter to plot the y-ccomponents of a vector
# (this example uses cell data)
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create pipeline
# Create an isosurface
$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA/combxyz.bin");
$pl3d->SetQFileName("$VTK_DATA/combq.bin");
$pl3d->SetScalarFunctionNumber(100);
$pl3d->SetVectorFunctionNumber(202);
$pl3d->Update;
$p2c = Graphics::VTK::PointDataToCellData->new;
$p2c->SetInput($pl3d->GetOutput);
$p2c->PassPointDataOff;
# extract y component of vector
$ad2fd = Graphics::VTK::AttributeDataToFieldDataFilter->new;
$ad2fd->SetInput($p2c->GetOutput);
$fd2ad = Graphics::VTK::FieldDataToAttributeDataFilter->new;
$fd2ad->SetInput($ad2fd->GetOutput);
$fd2ad->SetInputFieldToCellDataField;
$fd2ad->SetOutputAttributeDataToCellData;
$fd2ad->SetScalarComponent(0,'CellVectors',1);
# cut with plane
$plane = Graphics::VTK::Plane->new;
$plane->SetOrigin($pl3d->GetOutput->GetCenter);
$plane->SetNormal(-0.287,0,0.9579);
$planeCut = Graphics::VTK::Cutter->new;
$planeCut->SetInput($fd2ad->GetOutput);
$planeCut->SetCutFunction($plane);
$planeCut->Update;
$cutMapper = Graphics::VTK::PolyDataMapper->new;
$cutMapper->SetInput($planeCut->GetOutput);
$cutMapper->SetScalarRange($planeCut->GetOutput->GetCellData->GetScalars->GetRange);
$cutActor = Graphics::VTK::Actor->new;
$cutActor->SetMapper($cutMapper);
#outline
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineProp = $outlineActor->GetProperty;
$outlineProp->SetColor(0,0,0);
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($cutActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,300);
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(2.81,140.0);
$cam1->SetFocalPoint(9.445,0.393,30.5901);
$cam1->SetPosition(-0.1975,-15.2366,51.9064);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(-0.12802,0.826539,0.548129);
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->SetFileName("fieldAttr2.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
