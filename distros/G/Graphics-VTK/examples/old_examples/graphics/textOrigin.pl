#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Created oriented text
use Graphics::VTK::Tk::vtkInt;
# pipeline
$axes = Graphics::VTK::Axes->new;
$axes->SetOrigin(0,0,0);
$axesMapper = Graphics::VTK::PolyDataMapper->new;
$axesMapper->SetInput($axes->GetOutput);
$axesActor = Graphics::VTK::Actor->new;
$axesActor->SetMapper($axesMapper);
$atext = Graphics::VTK::VectorText->new;
$atext->SetText("Origin");
$textMapper = Graphics::VTK::PolyDataMapper->new;
$textMapper->SetInput($atext->GetOutput);
$textActor = Graphics::VTK::Follower->new;
$textActor->SetMapper($textMapper);
$textActor->SetScale(0.2,0.2,0.2);
$textActor->AddPosition(0,-0.1,0);
# create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($axesActor);
$ren1->AddActor($textActor);
$ren1->GetActiveCamera->Zoom(1.6);
$ren1->ResetCameraClippingRange;
$textActor->SetCamera($ren1->GetActiveCamera);
$renWin->Render;
$ren1->ResetCameraClippingRange;
$renWin->Render;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->SetFileName("textOrigin.tcl.ppm");
#renWin SaveImageAsPPM
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
