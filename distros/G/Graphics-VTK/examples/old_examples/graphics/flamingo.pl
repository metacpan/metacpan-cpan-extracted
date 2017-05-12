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
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$importer = Graphics::VTK::3DSImporter->new;
$importer->SetRenderWindow($renWin);
$importer->ComputeNormalsOn;
$importer->SetFileName("$VTK_DATA/Viewpoint/iflamigm.3ds");
$importer->Read;
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$importer->GetRenderer->SetBackground(0.1,0.2,0.4);
$importer->GetRenderWindow->SetSize(300,300);
# the importer created the renderer
$renCollection = $renWin->GetRenderers;
$renCollection->InitTraversal;
$ren = $renCollection->GetNextItem;
# change view up to +z
$ren->GetActiveCamera->SetPosition(0,1,0);
$ren->GetActiveCamera->SetFocalPoint(0,0,0);
$ren->GetActiveCamera->ComputeViewPlaneNormal;
$ren->GetActiveCamera->SetViewUp(0,0,1);
# let the renderer compute good position and focal point
$ren->ResetCamera;
$ren->GetActiveCamera->Dolly(1.4);
$ren1->ResetCameraClippingRange;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$MW->withdraw;
#renWin SetFileName "flamingo.tcl.ppm"
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
