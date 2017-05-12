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
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# lines make a nice test
#vtkLineSource line1
#  line1 SetPoint1 0 0 0
#  line1 SetPoint2 1 0 0
#  line1 SetResolution 100
#vtkLineSource line2
#  line2 SetPoint1 0 0 0
#  line2 SetPoint2 1 1 1
#  line2 SetResolution 50
#vtkAppendPolyData asource
#  asource AddInput [line1 GetOutput]
#  asource AddInput [line2 GetOutput]
$asource = Graphics::VTK::STLReader->new;
$asource->SetFileName("$VTK_DATA/42400-IDGH.stl");
$dataMapper = Graphics::VTK::PolyDataMapper->new;
$dataMapper->SetInput($asource->GetOutput);
$model = Graphics::VTK::Actor->new;
$model->SetMapper($dataMapper);
$model->GetProperty->SetColor(1,0,0);
$model->VisibilityOn;
@locators = qw/vtkPointLocator vtkCellLocator vtkOBBTree/;
$i = 1;
foreach $locator (@locators)
 {
  $locator{$i} = "Graphics::VTK::$locator"->new;
  $locator{$i}->AutomaticOff;
  $locator{$i}->SetMaxLevel(4);
  $boxes{$i} = Graphics::VTK::SpatialRepresentationFilter->new;
  $boxes{$i}->SetInput($asource->GetOutput);
  $boxes{$i}->SetSpatialRepresentation($locator{$i});
  $boxMapper{$i} = Graphics::VTK::PolyDataMapper->new;
  $boxMapper{$i}->SetInput($boxes{$i}->GetOutput);
  $boxActor{$i} = Graphics::VTK::Actor->new;
  $boxActor{$i}->SetMapper($boxMapper{$i});
  $boxActor{$i}->AddPosition($i * 15,0,0);
  $ren1->AddActor($boxActor{$i});
  $i += 1;
 }
# Add the actors to the renderer, set the background and size
$ren1->AddActor($model);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(500,200);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$camera = Graphics::VTK::Camera->new;
$camera->SetPosition(148.579,136.352,214.961);
$camera->SetFocalPoint(151.889,86.3178,223.333);
$camera->SetViewAngle(30);
$camera->SetViewUp(0,0,-1);
$camera->SetViewPlaneNormal(-0.0651119,0.984195,-0.164683);
$camera->SetClippingRange(1,100);
$ren1->SetActiveCamera($camera);
$renWin->Render;
$iren->Initialize;
#renWin SetFileName valid/SpatialRepAll.tcl.ppm
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
