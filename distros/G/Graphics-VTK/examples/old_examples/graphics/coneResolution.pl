#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# user interface command widget
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# create a rendering window and renderer
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create cones of varying resolution
$cone0 = Graphics::VTK::ConeSource->new;
$cone0->SetResolution(0);
$cone1 = Graphics::VTK::ConeSource->new;
$cone1->SetResolution(1);
$cone2 = Graphics::VTK::ConeSource->new;
$cone2->SetResolution(2);
$cone8 = Graphics::VTK::ConeSource->new;
$cone8->SetResolution(8);
$cone0Mapper = Graphics::VTK::PolyDataMapper->new;
$cone0Mapper->SetInput($cone0->GetOutput);
$cone0Actor = Graphics::VTK::Actor->new;
$cone0Actor->SetMapper($cone0Mapper);
$cone1Mapper = Graphics::VTK::PolyDataMapper->new;
$cone1Mapper->SetInput($cone1->GetOutput);
$cone1Actor = Graphics::VTK::Actor->new;
$cone1Actor->SetMapper($cone1Mapper);
$cone2Mapper = Graphics::VTK::PolyDataMapper->new;
$cone2Mapper->SetInput($cone2->GetOutput);
$cone2Actor = Graphics::VTK::Actor->new;
$cone2Actor->SetMapper($cone2Mapper);
$cone8Mapper = Graphics::VTK::PolyDataMapper->new;
$cone8Mapper->SetInput($cone8->GetOutput);
$cone8Actor = Graphics::VTK::Actor->new;
$cone8Actor->SetMapper($cone8Mapper);
# assign our actor to the renderer
$ren1->AddActor($cone0Actor);
$ren1->AddActor($cone1Actor);
$ren1->AddActor($cone2Actor);
$ren1->AddActor($cone8Actor);
$ren1->SetBackground('.5','.5','.5');
$ren1->GetActiveCamera->Elevation(30);
$ren1->GetActiveCamera->Dolly(1.3);
$ren1->ResetCameraClippingRange;
$renWin->SetSize(301,91);
$cone0Actor->SetPosition(-1.5,0,0);
$cone1Actor->SetPosition('-.5',0,0);
$cone2Actor->SetPosition('.5',0,0);
$cone8Actor->SetPosition(1.5,0,0);
$cone0Actor->GetProperty->SetDiffuseColor(1,0,0);
$cone1Actor->GetProperty->SetDiffuseColor(0,1,0);
$cone8Actor->GetProperty->BackfaceCullingOn;
$cone8Actor->GetProperty->SetDiffuseColor(0,0,1);
# enable user interface interactor
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
#renWin SetFileName "coneResolution.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;

Tk->MainLoop;
