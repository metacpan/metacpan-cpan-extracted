#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version to demonstrate smoothing
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create a semi-cylinder
$line = Graphics::VTK::LineSource->new;
$line->SetPoint1(0,1,0);
$line->SetPoint2(0,1,2);
$line->SetResolution(10);
$lineSweeper = Graphics::VTK::RotationalExtrusionFilter->new;
$lineSweeper->SetResolution(20);
$lineSweeper->SetInput($line->GetOutput);
$lineSweeper->SetAngle(270);
$bump = Graphics::VTK::BrownianPoints->new;
$bump->SetInput($lineSweeper->GetOutput);
$warp = Graphics::VTK::WarpVector->new;
$warp->SetInput($bump->GetPolyDataOutput);
$warp->SetScaleFactor('.2');
$smooth = Graphics::VTK::SmoothPolyDataFilter->new;
$smooth->SetInput($warp->GetPolyDataOutput);
$smooth->SetNumberOfIterations(50);
$smooth->BoundarySmoothingOn;
$smooth->SetFeatureAngle(120);
$smooth->SetEdgeAngle(90);
$smooth->SetRelaxationFactor('.025');
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($smooth->GetOutput);
$cylMapper = Graphics::VTK::PolyDataMapper->new;
$cylMapper->SetInput($normals->GetOutput);
$cylActor = Graphics::VTK::Actor->new;
$cylActor->SetMapper($cylMapper);
$cylActor->GetProperty->SetInterpolationToGouraud;
$cylActor->GetProperty->SetInterpolationToFlat;
$cylActor->GetProperty->SetColor(@Graphics::VTK::Colors::beige);
$originalMapper = Graphics::VTK::PolyDataMapper->new;
$originalMapper->SetInput($bump->GetPolyDataOutput);
$originalActor = Graphics::VTK::Actor->new;
$originalActor->SetMapper($originalMapper);
$originalActor->GetProperty->SetInterpolationToFlat;
$cylActor->GetProperty->SetColor(@Graphics::VTK::Colors::tomato);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($cylActor);
#ren1 AddActor originalActor
$ren1->SetBackground(1,1,1);
$renWin->SetSize(350,450);
$camera = Graphics::VTK::Camera->new;
$camera->SetClippingRange(0.576398,28.8199);
$camera->SetFocalPoint(0.0463079,-0.0356571,1.01993);
$camera->SetPosition(-2.47044,2.39516,-3.56066);
$camera->ComputeViewPlaneNormal;
$camera->SetViewUp(0.607296,-0.513537,-0.606195);
$ren1->SetActiveCamera($camera);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$renWin->SetFileName("valid/smoothCyl.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
