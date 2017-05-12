#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# Test the attribute to field data filter to plot the y-ccomponents of a vector
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
$iso = Graphics::VTK::ContourFilter->new;
$iso->SetInput($pl3d->GetOutput);
$iso->SetValue(0,'.38');
# Create a scalar that is the y-component of the vector and use it to
# color the isosurface.
$ad2fd = Graphics::VTK::AttributeDataToFieldDataFilter->new;
$ad2fd->SetInput($pl3d->GetOutput);
$fd2ad = Graphics::VTK::FieldDataToAttributeDataFilter->new;
$fd2ad->SetInput($ad2fd->GetOutput);
$fd2ad->SetInputFieldToPointDataField;
$fd2ad->SetOutputAttributeDataToPointData;
$fd2ad->SetScalarComponent(0,'PointVectors',1);
$probe = Graphics::VTK::ProbeFilter->new;
$probe->SetInput($iso->GetOutput);
$probe->SetSource($fd2ad->GetOutput);
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetMaxRecursionDepth(1000);
$normals->SetInput($probe->GetPolyDataOutput);
$normals->SetFeatureAngle(45);
$isoMapper = Graphics::VTK::PolyDataMapper->new;
$isoMapper->SetInput($normals->GetOutput);
$isoMapper->ScalarVisibilityOn;
$isoMapper->SetScalarRange(-25,350);
$isoActor = Graphics::VTK::LODActor->new;
$isoActor->SetMapper($isoMapper);
$isoActor->GetProperty->SetColor(@Graphics::VTK::Colors::bisque);
# Grid outline
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
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
$renWin->SetSize(300,300);
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
$renWin->SetFileName("fieldAttr.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
