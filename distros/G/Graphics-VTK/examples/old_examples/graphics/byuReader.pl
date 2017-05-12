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
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# read data
$byu = Graphics::VTK::BYUReader->new;
$byu->SetGeometryFileName('brain.g');
$byu->SetScalarFileName('brain.s');
$byu->SetDisplacementFileName('brain.d');
$byu->Update;
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($byu->GetOutput);
$mapper->SetScalarRange($byu->GetOutput->GetScalarRange);
$brain = Graphics::VTK::Actor->new;
$brain->SetMapper($mapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($brain);
$renWin->SetSize(320,240);
$cam1 = $ren1->GetActiveCamera;
$cam1->SetPosition(152.589,-135.901,173.068);
$cam1->SetFocalPoint(146.003,22.3839,0.260541);
$cam1->SetViewUp(-0.255578,-0.717754,-0.647695);
$ren1->ResetCameraClippingRange;
$iren->Initialize;
$renWin->Render;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
#renWin SetFileName byuReader.tcl.ppm
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
