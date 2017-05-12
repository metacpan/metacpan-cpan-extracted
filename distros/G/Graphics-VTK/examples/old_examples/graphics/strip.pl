#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#create triangle strip - won't see anything with backface culling on
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create triangle strip
$points = Graphics::VTK::Points->new;
$points->InsertPoint(0,0.0,0.0,0.0);
$points->InsertPoint(1,0.0,1.0,0.0);
$points->InsertPoint(2,1.0,0.0,0.0);
$points->InsertPoint(3,1.0,1.0,0.0);
$points->InsertPoint(4,2.0,0.0,0.0);
$points->InsertPoint(5,2.0,1.0,0.0);
$points->InsertPoint(6,3.0,0.0,0.0);
$points->InsertPoint(7,3.0,1.0,0.0);
$strips = Graphics::VTK::CellArray->new;
$strips->InsertNextCell(8);
#number of points
$strips->InsertCellPoint(0);
$strips->InsertCellPoint(1);
$strips->InsertCellPoint(2);
$strips->InsertCellPoint(3);
$strips->InsertCellPoint(4);
$strips->InsertCellPoint(5);
$strips->InsertCellPoint(6);
$strips->InsertCellPoint(7);
$profile = Graphics::VTK::PolyData->new;
$profile->SetPoints($points);
$profile->SetStrips($strips);
$map = Graphics::VTK::PolyDataMapper->new;
$map->SetInput($profile);
$strip = Graphics::VTK::Actor->new;
$strip->SetMapper($map);
$strip->GetProperty->SetColor(0.3800,0.7000,0.1600);
$strip->GetProperty->BackfaceCullingOff;
# Add the actors to the renderer, set the background and size
$ren1->AddActor($strip);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$renWin->Render;
#renWin SetFileName "strip.tcl.ppm"
#renWin SaveImageAsPPM
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
