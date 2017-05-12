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
# create pipeline
$pl3d2 = Graphics::VTK::PLOT3DReader->new;
$pl3d2->SetXYZFileName("$VTK_DATA/combxyz.bin");
$pl3d2->SetQFileName("$VTK_DATA/combq.bin");
$pl3d2->SetScalarFunctionNumber(153);
$pl3d2->Update;
$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA/combxyz.bin");
$pl3d->SetQFileName("$VTK_DATA/combq.bin");
$pl3d->SetScalarFunctionNumber(100);
$pl3d->SetVectorFunctionNumber(202);
$pl3d->Update;
$iso = Graphics::VTK::ContourFilter->new;
$iso->SetInput($pl3d->GetOutput);
$iso->SetValue(0,'.24');
$probe2 = Graphics::VTK::ProbeFilter->new;
$probe2->SetInput($iso->GetOutput);
$probe2->SetSource($pl3d2->GetOutput);
$cast2 = Graphics::VTK::CastToConcrete->new;
$cast2->SetInput($probe2->GetOutput);
$isoLines = Graphics::VTK::ContourFilter->new;
$isoLines->SetInput($cast2->GetOutput);
$isoLines->GenerateValues(10,0,1400);
$isoStrips = Graphics::VTK::Stripper->new;
$isoStrips->SetInput($isoLines->GetOutput);
$isoTubes = Graphics::VTK::TubeFilter->new;
$isoTubes->SetInput($isoStrips->GetOutput);
$isoTubes->SetRadius('.1');
$isoTubes->SetNumberOfSides(5);
$isoLinesMapper = Graphics::VTK::PolyDataMapper->new;
$isoLinesMapper->SetInput($isoTubes->GetOutput);
$isoLinesMapper->ScalarVisibilityOn;
$isoLinesMapper->SetScalarRange(0,1400);
$isoLinesActor = Graphics::VTK::Actor->new;
$isoLinesActor->SetMapper($isoLinesMapper);
$isoLinesActor->GetProperty->SetColor(@Graphics::VTK::Colors::bisque);
$isoMapper = Graphics::VTK::PolyDataMapper->new;
$isoMapper->SetInput($iso->GetOutput);
$isoMapper->ScalarVisibilityOff;
$isoActor = Graphics::VTK::Actor->new;
$isoActor->SetMapper($isoMapper);
$isoActor->GetProperty->SetColor(@Graphics::VTK::Colors::bisque);
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($isoLinesActor);
$ren1->AddActor($isoActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(640,480);
$ren1->SetBackground(0.1,0.2,0.4);
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(3.95297,50);
$cam1->SetFocalPoint(9.71821,0.458166,29.3999);
$cam1->SetPosition(2.7439,-37.3196,38.7167);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(-0.16123,0.264271,0.950876);
$cam1->Dolly(1.2);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
#renWin SetFileName "isoIntersect.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
