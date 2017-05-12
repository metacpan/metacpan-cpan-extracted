#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version of the Mace example
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$testsource = Graphics::VTK::Axes->new;
$originsource = Graphics::VTK::Axes->new;
$test = Graphics::VTK::Actor->new;
$origin = Graphics::VTK::Actor->new;
$originmapper = Graphics::VTK::PolyDataMapper->new;
$testmapper = Graphics::VTK::PolyDataMapper->new;
$originsource->SetScaleFactor(4000.0);
$originmapper->SetInput($originsource->GetOutput);
$originmapper->ImmediateModeRenderingOn;
$origin->SetMapper($originmapper);
$origin->GetProperty->SetAmbient(1.0);
$origin->GetProperty->SetDiffuse(0.0);
$ren1->AddActor($origin);
$testsource->SetScaleFactor(2000.0);
$testmapper->SetInput($testsource->GetOutput);
$testmapper->ImmediateModeRenderingOn;
$test->SetMapper($testmapper);
$test->GetProperty->SetAmbient(1.0);
$test->GetProperty->SetDiffuse(0.0);
$ren1->AddActor($test);
$test->SetPosition(0.0,1500.0,0.0);
$renWin->Render;
# do test rotations and renderings:
$test->RotateX(15.0);
$renWin->Render;
$test->RotateZ(30.0);
$renWin->Render;
$test->RotateY(45.0);
$renWin->Render;
#renWin SetFileName rot.tcl.ppm
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
