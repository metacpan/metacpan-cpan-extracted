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
$cylinder = Graphics::VTK::Cylinder->new;
$cylinder->SetRadius('.4');
$cylinder->SetCenter('.1','.2','.3');
$sample = Graphics::VTK::SampleFunction->new;
$sample->SetImplicitFunction($cylinder);
$iso = Graphics::VTK::ContourFilter->new;
$iso->SetInput($sample->GetOutput);
$iso->SetValue(0,0.0);
$isoMapper = Graphics::VTK::PolyDataMapper->new;
$isoMapper->SetInput($iso->GetOutput);
$isoMapper->ScalarVisibilityOff;
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
$back = Graphics::VTK::Property->new;
$back->SetDiffuseColor(@Graphics::VTK::Colors::banana);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($isoActor);
$isoActor->SetBackfaceProperty($back);
$ren1->SetBackground(1,1,1);
$ren1->GetActiveCamera->Azimuth(30);
$ren1->GetActiveCamera->Elevation(60);
$ren1->ResetCameraClippingRange;
$renWin->SetSize(500,500);
$renWin->Render;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->SetFileName("implicitCylinder.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
