#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInt;
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$tiff = Graphics::VTK::TIFFReader->new;
$tiff->SetFileName("$VTK_DATA/vtk.tif");
$atext = Graphics::VTK::Texture->new;
$atext->SetInput($tiff->GetOutput);
$atext->InterpolateOn;
$cube = Graphics::VTK::CubeSource->new;
$cube->SetXLength(3);
$cube->SetYLength(2);
$cube->SetZLength(1);
$cubeMapper = Graphics::VTK::PolyDataMapper->new;
$cubeMapper->SetInput($cube->GetOutput);
$cubeActor = Graphics::VTK::Actor->new;
$cubeActor->SetMapper($cubeMapper);
$cubeActor->SetTexture($atext);
$ren1->AddActor($cubeActor);
$ren1->SetBackground(0.2,0.3,0.4);
$renWin->SetSize(400,400);
$ren1->GetActiveCamera->Azimuth(45);
$ren1->GetActiveCamera->Elevation(30);
$ren1->ResetCameraClippingRange;
$renWin->Render;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
