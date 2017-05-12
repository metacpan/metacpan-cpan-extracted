#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# create a triangular texture on a sphere
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$aTriangularTexture = Graphics::VTK::TriangularTexture->new;
$aTriangularTexture->SetTexturePattern(2);
$aTriangularTexture->SetScaleFactor(1.3);
$aTriangularTexture->SetXSize(64);
$aTriangularTexture->SetYSize(64);
$aSphere = Graphics::VTK::SphereSource->new;
$aSphere->SetThetaResolution(20);
$aSphere->SetPhiResolution(20);
$tCoords = Graphics::VTK::TriangularTCoords->new;
$tCoords->SetInput($aSphere->GetOutput);
$triangleMapper = Graphics::VTK::PolyDataMapper->new;
$triangleMapper->SetInput($tCoords->GetOutput);
$aTexture = Graphics::VTK::Texture->new;
$aTexture->SetInput($aTriangularTexture->GetOutput);
$aTexture->InterpolateOn;
$banana = "0.8900 0.8100 0.3400";
$texturedActor = Graphics::VTK::Actor->new;
$texturedActor->SetMapper($triangleMapper);
$texturedActor->SetTexture($aTexture);
$texturedActor->GetProperty->BackfaceCullingOn;
$texturedActor->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::banana);
$texturedActor->GetProperty->SetSpecular('.4');
$texturedActor->GetProperty->SetSpecularPower(40);
$aCube = Graphics::VTK::CubeSource->new;
$aCube->SetXLength('.5');
$aCube->SetYLength('.5');
$aCubeMapper = Graphics::VTK::PolyDataMapper->new;
$aCubeMapper->SetInput($aCube->GetOutput);
$tomato = "1.0000 0.3882 0.2784";
$cubeActor = Graphics::VTK::Actor->new;
$cubeActor->SetMapper($aCubeMapper);
$cubeActor->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::tomato);
$slate_grey = "0.4392 0.5020 0.5647";
$ren1->SetBackground($slate_grey);
$ren1->AddActor($cubeActor);
$ren1->AddActor($texturedActor);
$ren1->GetActiveCamera->Zoom(1.5);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$renWin->SetFileName("triangularTCoords.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
