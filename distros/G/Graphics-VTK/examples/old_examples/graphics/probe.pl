#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# cut data
$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA/combxyz.bin");
$pl3d->SetQFileName("$VTK_DATA/combq.bin");
$pl3d->SetScalarFunctionNumber(100);
$pl3d->SetVectorFunctionNumber(202);
$pl3d->Update;
$plane = Graphics::VTK::Plane->new;
$plane->SetOrigin($pl3d->GetOutput->GetCenter);
$plane->SetNormal(-0.287,0,0.9579);
$planeCut = Graphics::VTK::Cutter->new;
$planeCut->SetInput($pl3d->GetOutput);
$planeCut->SetCutFunction($plane);
$probe = Graphics::VTK::ProbeFilter->new;
$probe->SetInput($planeCut->GetOutput);
$probe->SetSource($pl3d->GetOutput);
$cutMapper = Graphics::VTK::DataSetMapper->new;
$cutMapper->SetInput($probe->GetOutput);
$cutMapper->SetScalarRange($pl3d->GetOutput->GetPointData->GetScalars->GetRange);
$cutActor = Graphics::VTK::Actor->new;
$cutActor->SetMapper($cutMapper);
#extract plane
$compPlane = Graphics::VTK::StructuredGridGeometryFilter->new;
$compPlane->SetInput($pl3d->GetOutput);
$compPlane->SetExtent(0,100,0,100,9,9);
$planeMapper = Graphics::VTK::PolyDataMapper->new;
$planeMapper->SetInput($compPlane->GetOutput);
$planeMapper->ScalarVisibilityOff;
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($planeMapper);
$planeActor->GetProperty->SetRepresentationToWireframe;
$planeActor->GetProperty->SetColor(0,0,0);
#outline
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineProp = $outlineActor->GetProperty;
$outlineProp->SetColor(0,0,0);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($planeActor);
$ren1->AddActor($cutActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(3.95297,50);
$cam1->SetFocalPoint(9.71821,0.458166,29.3999);
$cam1->SetPosition(2.7439,-37.3196,38.7167);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(-0.16123,0.264271,0.950876);
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
#renWin SetFileName "probe.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
