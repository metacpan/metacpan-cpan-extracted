#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Demonstrate the use of clipping on polygonal data
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# create pipeline
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetRadius(1);
$sphere->SetPhiResolution(25);
$sphere->SetThetaResolution(25);
$plane = Graphics::VTK::Plane->new;
$plane->SetOrigin(0.25,0,0);
$plane->SetNormal(-1,-1,0);
$clipper = Graphics::VTK::ClipPolyData->new;
$clipper->SetInput($sphere->GetOutput);
$clipper->SetClipFunction($plane);
$clipper->GenerateClipScalarsOn;
$clipper->SetValue(0.0);
$clipMapper = Graphics::VTK::PolyDataMapper->new;
$clipMapper->SetInput($clipper->GetOutput);
$clipMapper->ScalarVisibilityOff;
$backProp = Graphics::VTK::Property->new;
$backProp->SetDiffuseColor(@Graphics::VTK::Colors::tomato);
$clipActor = Graphics::VTK::Actor->new;
$clipActor->SetMapper($clipMapper);
$clipActor->GetProperty->SetColor(@Graphics::VTK::Colors::peacock);
$clipActor->SetBackfaceProperty($backProp);
# Create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($clipActor);
$ren1->SetBackground(1,1,1);
$ren1->GetActiveCamera->Azimuth(30);
$ren1->GetActiveCamera->Elevation(30);
$ren1->GetActiveCamera->Dolly(1.2);
$ren1->ResetCameraClippingRange;
$renWin->SetSize(400,400);
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->SetFileName("clipSphere.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
