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
# Now create the RenderWindow, Renderer and Interactor
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$sphereModel = Graphics::VTK::SphereSource->new;
$sphereModel->SetThetaResolution(10);
$sphereModel->SetPhiResolution(10);
$voxelModel = Graphics::VTK::VoxelModeller->new;
$voxelModel->SetInput($sphereModel->GetOutput);
$voxelModel->SetSampleDimensions(21,21,21);
$aWriter = Graphics::VTK::DataSetWriter->new;
$aWriter->SetFileName('voxelModel.vtk');
$aWriter->SetInput($voxelModel->GetOutput);
$aWriter->Update;
$aReader = Graphics::VTK::DataSetReader->new;
$aReader->SetFileName('voxelModel.vtk');
$voxelSurface = Graphics::VTK::ContourFilter->new;
$voxelSurface->SetInput($aReader->GetOutput);
$voxelSurface->SetValue(0,'.999');
$voxelMapper = Graphics::VTK::PolyDataMapper->new;
$voxelMapper->SetInput($voxelSurface->GetOutput);
$voxelActor = Graphics::VTK::Actor->new;
$voxelActor->SetMapper($voxelMapper);
$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($sphereModel->GetOutput);
$sphereActor = Graphics::VTK::Actor->new;
$sphereActor->SetMapper($sphereMapper);
$ren1->AddActor($sphereActor);
$ren1->AddActor($voxelActor);
$ren1->SetBackground('.1','.2','.4');
$renWin->SetSize(256,256);
$ren1->GetActiveCamera->SetViewUp(0,-1,0);
$ren1->GetActiveCamera->Azimuth(180);
$ren1->GetActiveCamera->Dolly(1.75);
$ren1->ResetCameraClippingRange;
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->SetFileName("voxelModel.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
