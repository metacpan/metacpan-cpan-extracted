#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Generate implicit model of a sphere
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create renderer stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create pipeline
$squad = Graphics::VTK::Superquadric->new;
$squad->SetToroidal(1);
$squad->SetThickness(0.444);
$squad->SetPhiRoundness(0.3);
$squad->SetThetaRoundness(3);
$squad->SetSize(4);
$squad->SetScale(1,1,0.5);
$ntrans = Graphics::VTK::Transform->new;
$ntrans->Identity;
$ntrans->Scale(0.25,0.25,0.25);
$ntrans->Inverse;
$squad->SetTransform($ntrans);
$sample = Graphics::VTK::SampleFunction->new;
$sample->SetImplicitFunction($squad);
$sample->SetSampleDimensions(64,64,64);
$sample->ComputeNormalsOff;
$iso = Graphics::VTK::ContourFilter->new;
$iso->SetInput($sample->GetOutput);
$iso->SetValue(1,0);
$isoMapper = Graphics::VTK::PolyDataMapper->new;
$isoMapper->SetInput($iso->GetOutput);
$isoMapper->ScalarVisibilityOn;
$isoActor = Graphics::VTK::Actor->new;
$isoActor->SetMapper($isoMapper);
$isoActor->GetProperty->SetColor(@Graphics::VTK::Colors::peacock);
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($sample->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(0,0,0);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($isoActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(400,400);
$ren1->GetActiveCamera->Zoom(1.5);
$ren1->GetActiveCamera->Elevation(40);
$ren1->GetActiveCamera->Azimuth(-20);
$ren1->ResetCameraClippingRange;
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
#renWin SetFileName "superquad.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
