#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Convert a 3d Studio file to Renderman RIB
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$importer = Graphics::VTK::3DSImporter->new;
$importer->SetRenderWindow($renWin);
$importer->ComputeNormalsOn;
$importer->SetFileName("$VTK_DATA/harley-d.3ds");
$importer->Read;
$importer->GetRenderer->SetBackground(0.1,0.2,0.4);
$importer->GetRenderWindow->SetSize(300,300);
# change view up to +z
$ren1->GetActiveCamera->SetPosition('.6',-1,'.5');
$ren1->GetActiveCamera->SetFocalPoint(0,0,0);
$ren1->GetActiveCamera->ComputeViewPlaneNormal;
$ren1->GetActiveCamera->SetViewUp(0,0,1);
# let the renderer compute good position and focal point
$ren1->ResetCamera;
$ren1->GetActiveCamera->Dolly(1.4);
$ren1->ResetCameraClippingRange;
# export to rib format
if (Graphics::VTK::RIBExporter->can('new') ne "")
 {
  $exporter = Graphics::VTK::RIBExporter->new;
  $exporter->SetFilePrefix('importExport');
  $exporter->SetRenderWindow($importer->GetRenderWindow);
  $exporter->BackgroundOn;
  $exporter->Write;
 }
# now do the normal rendering
$renWin->Render;
$renWin->SetFileName("3dsToRIB.tcl.ppm");
#renWin SaveImageAsPPM
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
