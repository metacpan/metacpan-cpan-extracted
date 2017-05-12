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
# cut data
$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA/combxyz.bin");
$pl3d->SetQFileName("$VTK_DATA/combq.bin");
$pl3d->SetScalarFunctionNumber(100);
$pl3d->SetVectorFunctionNumber(202);
$pl3d->Update;
@range = $pl3d->GetOutput->GetPointData->GetScalars->GetRange;
$min = $range[0];
$max = $range[1];
$value = ($min + $max) / 2.0;
#vtkGridSynchronizedTemplates3D cf
$cf = Graphics::VTK::KitwareContourFilter->new;
$cf->SetInput($pl3d->GetOutput);
$cf->SetValue(0,$value);
#cf ComputeNormalsOff
$cfMapper = Graphics::VTK::PolyDataMapper->new;
$cfMapper->ImmediateModeRenderingOn;
$cfMapper->SetInput($cf->GetOutput);
$cfMapper->SetScalarRange($pl3d->GetOutput->GetPointData->GetScalars->GetRange);
$cfActor = Graphics::VTK::Actor->new;
$cfActor->SetMapper($cfMapper);
#outline
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(0,0,0);
## Graphics stuff
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($cfActor);
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
# loop over surfaces
for ($nloops = 0; $nloops < 2; $nloops += 1)
 {
  for ($i = 0; $i < 17; $i += 1)
   {
    $cf->SetValue(0,$min + ($i / 16.0) * ($max - $min));
    $renWin->Render;
   }
 }
$cf->SetValue(0,$min + 0.2 * ($max - $min));
$renWin->Render;
#renWin SetFileName aniIso.tcl.ppm
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
