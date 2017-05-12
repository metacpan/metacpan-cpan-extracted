#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# create selected streamlines in arteries
use Graphics::VTK::Colors;
#source $VTK_TCL/vtkInclude.tcl
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create pipeline
$reader = Graphics::VTK::StructuredPointsReader->new;
$reader->SetFileName("$VTK_DATA/carotid.vtk");
$psource = Graphics::VTK::PointSource->new;
$psource->SetNumberOfPoints(25);
$psource->SetCenter(133.1,116.3,5.0);
$psource->SetRadius(2.0);
$threshold = Graphics::VTK::ThresholdPoints->new;
$threshold->SetInput($reader->GetOutput);
$threshold->ThresholdByUpper(275);
$streamers = Graphics::VTK::StreamLine->new;
$streamers->SetInput($reader->GetOutput);
$streamers->SetSource($psource->GetOutput);
$streamers->SetMaximumPropagationTime(100.0);
$streamers->SetIntegrationStepLength(0.2);
$streamers->SpeedScalarsOn;
$streamers->SetTerminalSpeed('.1');
$tubes = Graphics::VTK::TubeFilter->new;
$tubes->SetInput($streamers->GetOutput);
$tubes->SetRadius(0.3);
$tubes->SetNumberOfSides(6);
$tubes->SetVaryRadius($Graphics::VTK::VARY_RADIUS_OFF);
$lut = Graphics::VTK::LookupTable->new;
$lut->SetHueRange('.667',0.0);
$lut->Build;
$streamerMapper = Graphics::VTK::PolyDataMapper->new;
$streamerMapper->SetInput($tubes->GetOutput);
$streamerMapper->SetScalarRange(2,10);
$streamerMapper->SetLookupTable($lut);
$streamerActor = Graphics::VTK::Actor->new;
$streamerActor->SetMapper($streamerMapper);
# contours of speed
$iso = Graphics::VTK::ContourFilter->new;
$iso->SetInput($reader->GetOutput);
$iso->SetValue(0,190);
$isoMapper = Graphics::VTK::PolyDataMapper->new;
$isoMapper->SetInput($iso->GetOutput);
$isoMapper->ScalarVisibilityOff;
$isoActor = Graphics::VTK::Actor->new;
$isoActor->SetMapper($isoMapper);
$isoActor->GetProperty->SetRepresentationToWireframe;
$isoActor->GetProperty->SetOpacity(0.25);
# outline
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($reader->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineProp = $outlineActor->GetProperty;
$outlineProp->SetColor(0,0,0);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($streamerActor);
$ren1->AddActor($isoActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$cam1 = Graphics::VTK::Camera->new;
$cam1->SetClippingRange(17.4043,870.216);
$cam1->SetFocalPoint(136.71,104.025,23);
$cam1->SetPosition(204.747,258.939,63.7925);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(-0.102647,-0.210897,0.972104);
$cam1->Zoom(1.6);
$ren1->SetActiveCamera($cam1);
$iren->Initialize;
# render the image
#iren SetUserMethod {
#  commandloop "puts -nonewline vtki>"; puts cont}
#$renWin->Render;
#renWin SetFileName "streamV.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;

Tk->MainLoop;
