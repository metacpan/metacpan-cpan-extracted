#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Demonstrates rendering a large image
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
$ren1 = Graphics::VTK::Renderer->new;
$renWin1 = Graphics::VTK::RenderWindow->new;
$renWin1->AddRenderer($ren1);
$importer = Graphics::VTK::3DSImporter->new;
$importer->SetRenderWindow($renWin1);
$importer->ComputeNormalsOn;
$importer->SetFileName("$VTK_DATA/Viewpoint/iflamigm.3ds");
$importer->Read;
$importer->GetRenderer->SetBackground(0.1,0.2,0.4);
$importer->GetRenderWindow->SetSize(125,125);
# the importer created the renderer
$renCollection = $renWin1->GetRenderers;
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
# render the large image
$MW->withdraw;
$renderLarge = Graphics::VTK::RenderLargeImage->new;
$renderLarge->SetInput($ren1);
$renderLarge->SetMagnification(4);
$renderLarge->Update;
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($renderLarge->GetOutput);
$viewer->SetColorWindow(255);
$viewer->SetColorLevel(127.5);
$viewer->Render;
$writer = Graphics::VTK::PNMWriter->new;
$writer->SetFileName('largeImage.tcl.ppm');
$writer->SetInput($renderLarge->GetOutput);
#  writer Write
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
