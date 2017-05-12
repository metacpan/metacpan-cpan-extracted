#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create renderer stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create pipeline
$cow = Graphics::VTK::BYUReader->new;
$cow->SetGeometryFileName("$VTK_DATA/Viewpoint/cow.g");
$cowMapper = Graphics::VTK::PolyDataMapper->new;
$cowMapper->SetInput($cow->GetOutput);
$cowActor = Graphics::VTK::Actor->new;
$cowActor->SetMapper($cowMapper);
$cowActor->GetProperty->SetDiffuseColor(0.9608,0.8706,0.7020);
$cowAxesSource = Graphics::VTK::Axes->new;
$cowAxesSource->SetScaleFactor(10);
$cowAxesSource->SetOrigin(0,0,0);
$cowAxesMapper = Graphics::VTK::PolyDataMapper->new;
$cowAxesMapper->SetInput($cowAxesSource->GetOutput);
$cowAxes = Graphics::VTK::Actor->new;
$cowAxes->SetMapper($cowAxesMapper);
$ren1->AddActor($cowAxes);
$cowAxes->VisibilityOff;
# Add the actors to the renderer, set the background and size
$ren1->AddActor($cowActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(640,480);
$ren1->GetActiveCamera->Azimuth(0);
$ren1->GetActiveCamera->Dolly(1.4);
$ren1->ResetCameraClippingRange;
$cowAxes->VisibilityOn;
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
$cowTransform = Graphics::VTK::Transform->new;
#
sub walk
{
 my $i;
 $cowActor->SetOrientation(0,0,0);
 $cowActor->SetOrigin(0,0,0);
 $cowActor->SetPosition(0,0,0);
 $ren1->ResetCameraClippingRange;
 $renWin->Render;
 $renWin->Render;
 $renWin->EraseOff;
 for ($i = 1; $i <= 6; $i += 1)
  {
   #	cowActor RotateY 60
   $cowTransform->Identity;
   $cowTransform->RotateY($i * 60);
   $cowTransform->Translate(0,0,5);
   $cowActor->SetUserMatrix($cowTransform->GetMatrix);
   $renWin->Render;
   $renWin->Render;
  }
 $renWin->EraseOn;
}
#
sub walk2
{
 my $i;
 $cowActor->SetOrientation(0,0,0);
 $ren1->ResetCameraClippingRange;
 $renWin->Render;
 $renWin->Render;
 $renWin->EraseOff;
 $cowActor->SetOrigin(0,0,-5);
 $cowActor->SetPosition(0,0,5);
 $cowTransform->Identity;
 $cowActor->SetUserMatrix($cowTransform->GetMatrix);
 for ($i = 1; $i <= 6; $i += 1)
  {
   $cowActor->RotateY(60);
   $renWin->Render;
   $renWin->Render;
  }
 $renWin->EraseOn;
}
#
sub walk3
{
 my $i;
 $cowActor->SetOrientation(0,0,0);
 $ren1->ResetCameraClippingRange;
 $renWin->Render;
 $renWin->Render;
 $renWin->EraseOff;
 $cowActor->SetOrigin(0,0,-5);
 $cowActor->SetPosition(0,0,0);
 $cowTransform->Identity;
 $cowActor->SetUserMatrix($cowTransform->GetMatrix);
 for ($i = 1; $i <= 6; $i += 1)
  {
   $cowActor->RotateY(60);
   $renWin->Render;
   $renWin->Render;
  }
 $renWin->EraseOn;
}
#
sub walk4
{
 my $i;
 $cowActor->SetOrientation(0,0,0);
 $ren1->ResetCameraClippingRange;
 $renWin->Render;
 $renWin->Render;
 $renWin->EraseOff;
 $cowActor->SetOrigin(6.11414,1.27386,'.015175');
 $cowActor->SetOrigin(0,0,0);
 $cowActor->SetPosition(0,0,0);
 $cowTransform->Identity;
 $cowActor->SetUserMatrix($cowTransform->GetMatrix);
 for ($i = 1; $i <= 6; $i += 1)
  {
   $cowActor->RotateWXYZ(60,2.19574,-1.42455,'-.0331036');
   $renWin->Render;
   $renWin->Render;
  }
 $renWin->EraseOn;
}
walk4();
$renWin->EraseOff;
#renWin SetFileName "walkCow.tcl.ppm"
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
