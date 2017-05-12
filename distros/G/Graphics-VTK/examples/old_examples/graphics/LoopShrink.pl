#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# demonstrates a pipeline loop.
# user interface command widget
use Graphics::VTK::Tk::vtkInt;
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetThetaResolution(12);
$sphere->SetPhiResolution(12);
$shrink = Graphics::VTK::ShrinkFilter->new;
$shrink->SetInput($sphere->GetOutput);
$shrink->SetShrinkFactor(0.95);
$colorIt = Graphics::VTK::ElevationFilter->new;
$colorIt->SetInput($shrink->GetOutput);
$colorIt->SetLowPoint(0,0,'-.5');
$colorIt->SetHighPoint(0,0,'.5');
$mapper = Graphics::VTK::DataSetMapper->new;
$mapper->SetInput($colorIt->GetOutput);
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
# prevent the tk window from showing up then start the event loop
# create a rendering window and renderer
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($actor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(300,300);
#execute first time
$renWin->Render;
# create the loop
$shrink->SetInput($colorIt->GetOutput);
# begin looping
for ($i = 0; $i < 40; $i += 1)
 {
  $renWin->Render;
 }
# enable user interface interactor
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
# break the loop (reference-counting loop) so that object will be deleted
$shrink->SetInput($sphere->GetOutput);
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
