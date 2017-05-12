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
$plane = Graphics::VTK::Plane->new;
$plane->SetNormal(1,0,0);
$skinClipper = Graphics::VTK::ClipPolyData->new;
$skinClipper->SetInput($skinReader->GetOutput);
$skinClipper->SetClipFunction($plane);
$reflect = Graphics::VTK::Transform->new;
$reflect->Scale(-1,1,1);
$skinReflect = Graphics::VTK::TransformPolyDataFilter->new;
$skinReflect->SetTransform($reflect);
$skinReflect->SetInput($skinClipper->GetOutput);
$skinReverse = Graphics::VTK::ReverseSense->new;
$skinReverse->SetInput($skinReflect->GetOutput);
$skinReverse->ReverseNormalsOn;
$skinReverse->ReverseCellsOff;
$reflectedMapper = Graphics::VTK::PolyDataMapper->new;
$reflectedMapper->SetInput($skinReverse->GetOutput);
$reflected = Graphics::VTK::Actor->new;
$reflected->SetMapper($reflectedMapper);
$reflected->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::flesh);
$reflected->GetProperty->SetDiffuse('.8');
$reflected->GetProperty->SetSpecular('.5');
$reflected->GetProperty->SetSpecularPower(30);
$reflected->GetProperty->BackfaceCullingOn;
$ren1->AddActor($reflected);
$skinReverse2 = Graphics::VTK::ReverseSense->new;
$skinReverse2->SetInput($skinClipper->GetOutput);
$skinReverse2->ReverseNormalsOn;
$skinReverse2->ReverseCellsOn;
$skinMapper = Graphics::VTK::PolyDataMapper->new;
$skinMapper->SetInput($skinReverse2->GetOutput);
$skin = Graphics::VTK::Actor->new;
$skin->SetMapper($skinMapper);
$ren1->AddActor($skin);
$ren1->SetBackground('.1','.2','.4');
$renWin->SetSize(640,512);
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
$renWin->SetFileName("reverse.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
