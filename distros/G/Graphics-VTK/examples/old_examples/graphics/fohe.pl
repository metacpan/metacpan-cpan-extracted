#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version of motor visualization
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# read a vtk file
$byu = Graphics::VTK::BYUReader->new;
$byu->SetGeometryFileName("$VTK_DATA/fohe.g");
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($byu->GetOutput);
$byuMapper = Graphics::VTK::PolyDataMapper->new;
$byuMapper->SetInput($normals->GetOutput);
$byuActor = Graphics::VTK::Actor->new;
$byuActor->SetMapper($byuMapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($byuActor);
$ren1->SetBackground(0.2,0.3,0.4);
$renWin->SetSize(500,500);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
#renWin SetFileName "fohe.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
