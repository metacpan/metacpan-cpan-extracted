#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# user interface command widget
use Graphics::VTK::Tk::vtkInt;
# create a rendering window and renderer
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$cube = Graphics::VTK::ConeSource->new;
#vtkPlaneSource cube
#  cube SetResolution 5 5
#vtkCubeSource cube
$clean = Graphics::VTK::CleanPolyData->new;
#remove duplicate vertices and edges
$clean->SetInput($cube->GetOutput);
$extract = Graphics::VTK::ExtractEdges->new;
$extract->SetInput($clean->GetOutput);
$tubes = Graphics::VTK::TubeFilter->new;
$tubes->SetInput($extract->GetOutput);
$tubes->SetRadius(0.05);
$tubes->SetNumberOfSides(6);
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($tubes->GetOutput);
$cubeActor = Graphics::VTK::Actor->new;
$cubeActor->SetMapper($mapper);
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetRadius(0.080);
$verts = Graphics::VTK::Glyph3D->new;
$verts->SetInput($cube->GetOutput);
$verts->SetSource($sphere->GetOutput);
$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($verts->GetOutput);
$vertActor = Graphics::VTK::Actor->new;
$vertActor->SetMapper($sphereMapper);
$vertActor->GetProperty->SetColor(0,0,1);
# assign our actor to the renderer
$ren1->AddActor($cubeActor);
$ren1->AddActor($vertActor);
# enable user interface interactor
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
#renWin SetFileName "cubeEdges.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
