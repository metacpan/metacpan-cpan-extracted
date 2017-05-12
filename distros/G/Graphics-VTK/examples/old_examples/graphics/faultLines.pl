#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Create a constrained Delaunay triangulation following fault lines.
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# get some nice colors
use Graphics::VTK::Colors;
# create some points
$reader = Graphics::VTK::PolyDataReader->new;
$reader->SetFileName("$VTK_DATA/faults.vtk");
# triangulate them
$cleaner = Graphics::VTK::CleanPolyData->new;
$cleaner->SetInput($reader->GetOutput);
$del = Graphics::VTK::Delaunay2D->new;
$del->SetInput($cleaner->GetOutput);
$del->SetSource($cleaner->GetOutput);
$del->SetTolerance(0.00001);
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($del->GetOutput);
$mapMesh = Graphics::VTK::PolyDataMapper->new;
$mapMesh->SetInput($normals->GetOutput);
$meshActor = Graphics::VTK::Actor->new;
$meshActor->SetMapper($mapMesh);
$meshActor->GetProperty->SetColor(@Graphics::VTK::Colors::beige);
$tuber = Graphics::VTK::TubeFilter->new;
$tuber->SetInput($cleaner->GetOutput);
$tuber->SetRadius(25);
$mapLines = Graphics::VTK::PolyDataMapper->new;
$mapLines->SetInput($tuber->GetOutput);
$linesActor = Graphics::VTK::Actor->new;
$linesActor->SetMapper($mapLines);
$linesActor->GetProperty->SetColor(1,0,0);
$linesActor->GetProperty->SetColor(@Graphics::VTK::Colors::tomato);
# Create graphics objects
# Create the rendering window, renderer, and interactive renderer
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($linesActor);
$ren1->AddActor($meshActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(350,250);
$cam1 = Graphics::VTK::Camera->new;
$cam1->SetClippingRange(2580,129041);
$cam1->SetFocalPoint(461550,'6.58e+006',2132);
$cam1->SetPosition(463960,'6.559e+06',16982);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(-0.321899,0.522244,0.78971);
$light = Graphics::VTK::Light->new;
$light->SetPosition(0,0,1);
$light->SetFocalPoint(0,0,0);
$ren1->SetActiveCamera($cam1);
$ren1->AddLight($light);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$ren1->GetActiveCamera->Zoom(1.5);
$iren->LightFollowCameraOff;
$iren->Initialize;
$renWin->SetFileName("faultLines.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
