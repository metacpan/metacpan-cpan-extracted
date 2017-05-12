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
$plane = Graphics::VTK::PlaneSource->new;
$plane->SetXResolution(25);
$plane->SetYResolution(25);
$plane->SetOrigin(-1,-1,0);
$plane->SetPoint1(1,-1,0);
$plane->SetPoint2(-1,1,0);
$transformSphere = Graphics::VTK::Transform->new;
$transformSphere->Identity;
$transformSphere->Translate('.4','-.4',0);
$transformSphere->Inverse;
$sphere = Graphics::VTK::Sphere->new;
$sphere->SetTransform($transformSphere);
$sphere->SetRadius('.5');
$transformCylinder = Graphics::VTK::Transform->new;
$transformCylinder->Identity;
$transformCylinder->Translate('-.4','.4',0);
$transformCylinder->RotateZ(30);
$transformCylinder->RotateY(60);
$transformCylinder->RotateX(90);
$transformCylinder->Inverse;
$cylinder = Graphics::VTK::Cylinder->new;
$cylinder->SetTransform($transformCylinder);
$cylinder->SetRadius('.3');
$boolean = Graphics::VTK::ImplicitBoolean->new;
$boolean->AddFunction($cylinder);
$boolean->AddFunction($sphere);
$clipper = Graphics::VTK::ClipPolyData->new;
$clipper->SetInput($plane->GetOutput);
$clipper->SetClipFunction($boolean);
$clipper->GenerateClippedOutputOn;
$clipper->GenerateClipScalarsOn;
$clipper->SetValue(0);
$clipMapper = Graphics::VTK::PolyDataMapper->new;
$clipMapper->SetInput($clipper->GetOutput);
$clipMapper->ScalarVisibilityOff;
$clipActor = Graphics::VTK::Actor->new;
$clipActor->SetMapper($clipMapper);
$clipActor->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::black);
$clipActor->GetProperty->SetRepresentationToWireframe;
$clipInsideMapper = Graphics::VTK::PolyDataMapper->new;
$clipInsideMapper->SetInput($clipper->GetClippedOutput);
$clipInsideMapper->ScalarVisibilityOff;
$clipInsideActor = Graphics::VTK::Actor->new;
$clipInsideActor->SetMapper($clipInsideMapper);
$clipInsideActor->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::dim_grey);
# Create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($clipActor);
#[clipActor GetProperty] SetWireframe
$ren1->AddActor($clipInsideActor);
$ren1->SetBackground(1,1,1);
$ren1->GetActiveCamera->Dolly(1.5);
$ren1->ResetCameraClippingRange;
$renWin->SetSize(512,512);
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
#renWin SetFileName "clipSphCyl.tcl.ppm"
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
