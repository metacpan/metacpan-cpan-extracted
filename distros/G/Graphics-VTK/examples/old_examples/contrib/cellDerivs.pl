#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Demonstrate computation of cell derivatives
# Compute vorticity - show vorticity vectors as hedgehogs
use Graphics::VTK::Tk::vtkInt;
# create reader and extract the velocity and temperature
$reader = Graphics::VTK::UnstructuredGridReader->new;
$reader->SetFileName("$VTK_DATA/cylFlow.vtk");
$fd2ad = Graphics::VTK::FieldDataToAttributeDataFilter->new;
$fd2ad->SetInput($reader->GetOutput);
$fd2ad->SetInputFieldToPointDataField;
$fd2ad->SetScalarComponent(0,'Temperature',0);
$fd2ad->SetVectorComponent(0,'Velocity',0);
$fd2ad->SetVectorComponent(1,'Velocity',1);
$fd2ad->SetVectorComponent(2,'Velocity',2);
$fd2ad->Update;
#to Support GetScalarRange call
# display the mesh
$gridMapper = Graphics::VTK::DataSetMapper->new;
$gridMapper->SetInput($fd2ad->GetOutput);
$gridMapper->SetScalarRange($fd2ad->GetOutput->GetScalarRange);
$gridActor = Graphics::VTK::Actor->new;
$gridActor->SetMapper($gridMapper);
# compute derivatives of data and get the vorticity at the cell centers
$derivs = Graphics::VTK::CellDerivatives->new;
$derivs->SetInput($fd2ad->GetOutput);
$derivs->SetVectorModeToComputeVorticity;
# get points in the center of cells so we can put vorticity glyphs there
$cc = Graphics::VTK::CellCenters->new;
$cc->SetInput($derivs->GetOutput);
# some glyphs indicating vorticity
$mask = Graphics::VTK::MaskPoints->new;
$mask->SetInput($cc->GetOutput);
$mask->RandomModeOn;
$mask->SetMaximumNumberOfPoints(100);
$hhog = Graphics::VTK::HedgeHog->new;
$hhog->SetInput($mask->GetOutput);
$mapHog = Graphics::VTK::PolyDataMapper->new;
$mapHog->SetInput($hhog->GetOutput);
$mapHog->ScalarVisibilityOff;
$hogActor = Graphics::VTK::Actor->new;
$hogActor->SetMapper($mapHog);
$hogActor->GetProperty->SetColor(1,0,0);
# Create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($gridActor);
$ren1->AddActor($hogActor);
$camera = $ren1->GetActiveCamera;
$camera->SetClippingRange(3.10849,208.252);
$camera->SetFocalPoint(3.75439,-0.000334978,-1.27252);
$camera->SetPosition(-1.18886,10.737,-11.3642);
$camera->ComputeViewPlaneNormal;
$camera->SetViewUp(0.0828035,-0.662002,-0.744914);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,250);
$iren->Initialize;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->SetFileName("cellDerivs.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
