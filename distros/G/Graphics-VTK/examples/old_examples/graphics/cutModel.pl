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
$skinReader = Graphics::VTK::PolyDataReader->new;
$skinReader->SetFileName("$VTK_DATA/skin.vtk");
$skinMapper = Graphics::VTK::PolyDataMapper->new;
$skinMapper->SetInput($skinReader->GetOutput);
$skin = Graphics::VTK::Actor->new;
$skin->SetMapper($skinMapper);
$skin->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::flesh);
$skin->GetProperty->SetDiffuse('.8');
$skin->GetProperty->SetSpecular('.5');
$skin->GetProperty->SetSpecularPower(30);
$ren1->AddActor($skin);
$aPlane = Graphics::VTK::Plane->new;
$aPlane->SetOrigin(0,1.5,0);
$aPlane->SetNormal(0,1,0);
$aCutPlane = Graphics::VTK::Cutter->new;
$aCutPlane->SetInput($skinReader->GetOutput);
$aCutPlane->SetCutFunction($aPlane);
$aCutPlane->GenerateValues(23,1.5,139.5);
$aStripper = Graphics::VTK::Stripper->new;
$aStripper->SetInput($aCutPlane->GetOutput);
$tubes = Graphics::VTK::TubeFilter->new;
$tubes->SetInput($aStripper->GetOutput);
$tubes->SetNumberOfSides(8);
$tubes->UseDefaultNormalOn;
$tubes->SetDefaultNormal(0,1,0);
$cutPlaneMapper = Graphics::VTK::PolyDataMapper->new;
$cutPlaneMapper->SetInput($tubes->GetOutput);
$cutPlaneMapper->SetScalarRange(-100,100);
$cut = Graphics::VTK::Actor->new;
$cut->SetMapper($cutPlaneMapper);
$ren1->AddActor($cut);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(640,512);
$ren1->GetActiveCamera->SetViewUp(0,-1,0);
$ren1->GetActiveCamera->Azimuth(230);
$ren1->GetActiveCamera->Elevation(30);
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
#renWin SetFileName "cutModel.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
