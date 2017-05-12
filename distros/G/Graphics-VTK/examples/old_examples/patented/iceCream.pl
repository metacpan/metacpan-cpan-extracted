#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# create ice-cream cone
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create implicit function primitives
$cone = Graphics::VTK::Cone->new;
$cone->SetAngle(20);
$vertPlane = Graphics::VTK::Plane->new;
$vertPlane->SetOrigin('.1',0,0);
$vertPlane->SetNormal(-1,0,0);
$basePlane = Graphics::VTK::Plane->new;
$basePlane->SetOrigin(1.2,0,0);
$basePlane->SetNormal(1,0,0);
$iceCream = Graphics::VTK::Sphere->new;
$iceCream->SetCenter(1.333,0,0);
$iceCream->SetRadius(0.5);
$bite = Graphics::VTK::Sphere->new;
$bite->SetCenter(1.5,0,0.5);
$bite->SetRadius(0.25);
# combine primitives to build ice-cream cone
$theCone = Graphics::VTK::ImplicitBoolean->new;
$theCone->SetOperationTypeToIntersection;
$theCone->AddFunction($cone);
$theCone->AddFunction($vertPlane);
$theCone->AddFunction($basePlane);
$theCream = Graphics::VTK::ImplicitBoolean->new;
$theCream->SetOperationTypeToDifference;
$theCream->AddFunction($iceCream);
$theCream->AddFunction($bite);
# iso-surface to create geometry
$theConeSample = Graphics::VTK::SampleFunction->new;
$theConeSample->SetImplicitFunction($theCone);
$theConeSample->SetModelBounds(-1,1.5,-1.25,1.25,-1.25,1.25);
$theConeSample->SetSampleDimensions(60,60,60);
$theConeSample->ComputeNormalsOff;
$theConeSurface = Graphics::VTK::MarchingContourFilter->new;
$theConeSurface->SetInput($theConeSample->GetOutput);
$theConeSurface->SetValue(0,0.0);
$coneMapper = Graphics::VTK::PolyDataMapper->new;
$coneMapper->SetInput($theConeSurface->GetOutput);
$coneMapper->ScalarVisibilityOff;
$coneActor = Graphics::VTK::Actor->new;
$coneActor->SetMapper($coneMapper);
$coneActor->GetProperty->SetColor(@Graphics::VTK::Colors::chocolate);
# iso-surface to create geometry
$theCreamSample = Graphics::VTK::SampleFunction->new;
$theCreamSample->SetImplicitFunction($theCream);
$theCreamSample->SetModelBounds(0,2.5,-1.25,1.25,-1.25,1.25);
$theCreamSample->SetSampleDimensions(60,60,60);
$theCreamSample->ComputeNormalsOff;
$theCreamSurface = Graphics::VTK::MarchingContourFilter->new;
$theCreamSurface->SetInput($theCreamSample->GetOutput);
$theCreamSurface->SetValue(0,0.0);
$creamMapper = Graphics::VTK::PolyDataMapper->new;
$creamMapper->SetInput($theCreamSurface->GetOutput);
$creamMapper->ScalarVisibilityOff;
$creamActor = Graphics::VTK::Actor->new;
$creamActor->SetMapper($creamMapper);
$creamActor->GetProperty->SetColor(@Graphics::VTK::Colors::mint);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($coneActor);
$ren1->AddActor($creamActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$ren1->GetActiveCamera->Roll(90);
$iren->Initialize;
#renWin SetFileName "iceCream.tcl.ppm"
#renWin SaveImageAsPPM
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
