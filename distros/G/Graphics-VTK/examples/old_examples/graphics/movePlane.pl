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
use Graphics::VTK::Colors;
# create planes
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create pipeline
$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA/combxyz.bin");
$pl3d->SetQFileName("$VTK_DATA/combq.bin");
$pl3d->SetScalarFunctionNumber(100);
$pl3d->SetVectorFunctionNumber(202);
$pl3d->Update;
$plane = Graphics::VTK::StructuredGridGeometryFilter->new;
$plane->SetInput($pl3d->GetOutput);
$plane->SetExtent(0,100,0,100,0,0);
$planeMapper = Graphics::VTK::PolyDataMapper->new;
$planeMapper->SetInput($plane->GetOutput);
$planeMapper->SetScalarRange(0.197813,0.710419);
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($planeMapper);
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(@Graphics::VTK::Colors::black);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($planeActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$iren->Initialize;
$renWin->Render;
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(3.95297,50);
$cam1->SetFocalPoint(8.88908,0.595038,29.3342);
$cam1->SetPosition(-12.3332,31.7479,41.2387);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(0.060772,-0.319905,0.945498);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
for ($j = 0; $j < 3; $j += 1)
 {
  for ($i = 0; $i < 25; $i += 1)
   {
    $plane->SetExtent(0,100,0,100,$i,$i);
    $renWin->Render;
   }
 }
#renWin SetFileName "movePlane.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
