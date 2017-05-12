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
$cone = Graphics::VTK::BYUReader->new;
$cone->SetGeometryFileName("$VTK_DATA/Viewpoint/cow.g");
$coneMapper = Graphics::VTK::PolyDataMapper->new;
$coneMapper->SetInput($cone->GetOutput);
$coneActor = Graphics::VTK::Actor->new;
$coneActor->SetMapper($coneMapper);
$coneActor->GetProperty->SetDiffuseColor(0.9608,0.8706,0.7020);
$coneAxesSource = Graphics::VTK::Axes->new;
$coneAxesSource->SetScaleFactor(10);
$coneAxesSource->SetOrigin(0,0,0);
$coneAxesMapper = Graphics::VTK::PolyDataMapper->new;
$coneAxesMapper->SetInput($coneAxesSource->GetOutput);
$coneAxes = Graphics::VTK::Actor->new;
$coneAxes->SetMapper($coneAxesMapper);
$ren1->AddActor($coneAxes);
$coneAxes->VisibilityOff;
# Add the actors to the renderer, set the background and size
$ren1->AddActor($coneActor);
$ren1->SetBackground(0.1,0.2,0.4);
#renWin SetSize 1280 1024
$renWin->SetSize(640,480);
$ren1->GetActiveCamera->Azimuth(0);
$ren1->GetActiveCamera->Dolly(1.4);
$ren1->ResetCameraClippingRange;
$coneAxes->VisibilityOn;
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
#
sub RotateX
{
 my $i;
 $coneActor->SetOrientation(0,0,0);
 $ren1->ResetCameraClippingRange;
 $renWin->Render;
 $renWin->Render;
 $renWin->EraseOff;
 for ($i = 1; $i <= 6; $i += 1)
  {
   $coneActor->RotateX(60);
   $renWin->Render;
   $renWin->Render;
  }
 $renWin->EraseOn;
}
#
sub RotateY
{
 my $i;
 $coneActor->SetOrientation(0,0,0);
 $ren1->ResetCameraClippingRange;
 $renWin->Render;
 $renWin->Render;
 $renWin->EraseOff;
 for ($i = 1; $i <= 6; $i += 1)
  {
   $coneActor->RotateY(60);
   $renWin->Render;
   $renWin->Render;
  }
 $renWin->EraseOn;
}
#
sub RotateZ
{
 my $i;
 $coneActor->SetOrientation(0,0,0);
 $ren1->ResetCameraClippingRange;
 $renWin->Render;
 $renWin->Render;
 $renWin->EraseOff;
 for ($i = 1; $i <= 6; $i += 1)
  {
   $coneActor->RotateZ(60);
   $renWin->Render;
   $renWin->Render;
  }
 $renWin->EraseOn;
}
#
sub RotateXY
{
 my $i;
 $coneActor->SetOrientation(0,0,0);
 $coneActor->RotateX(60);
 $ren1->ResetCameraClippingRange;
 $renWin->Render;
 $renWin->Render;
 $renWin->EraseOff;
 for ($i = 1; $i <= 6; $i += 1)
  {
   $coneActor->RotateY(60);
   $renWin->Render;
   $renWin->Render;
  }
 $renWin->EraseOn;
}
RotateX();
$renWin->SetFileName('rotX.ppm');
#renWin SaveImageAsPPM
RotateY();
$renWin->SetFileName('rotY.ppm');
#renWin SaveImageAsPPM
RotateZ();
$renWin->SetFileName('rotZ.ppm');
#renWin SaveImageAsPPM
RotateXY();
$renWin->EraseOff;
$renWin->SetFileName('rotXY.ppm');
#renWin SaveImageAsPPM
#renWin SetFileName "rotations.tcl.ppm"
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
