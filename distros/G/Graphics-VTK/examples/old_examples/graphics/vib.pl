#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version of plate vibration
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# read a vtk file
$plate = Graphics::VTK::PolyDataReader->new;
$plate->SetFileName("$VTK_DATA/plate.vtk");
$plate->SetVectorsName("mode2");
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($plate->GetOutput);
$warp = Graphics::VTK::WarpVector->new;
$warp->SetInput($normals->GetOutput);
$warp->SetScaleFactor(0.5);
$color = Graphics::VTK::VectorDot->new;
$color->SetInput($warp->GetOutput);
$plateMapper = Graphics::VTK::DataSetMapper->new;
$plateMapper->SetInput($warp->GetOutput);
#    plateMapper SetInput [color GetOutput]
$plateActor = Graphics::VTK::Actor->new;
$plateActor->SetMapper($plateMapper);
# create the outline
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($plate->GetOutput);
$spikeMapper = Graphics::VTK::PolyDataMapper->new;
$spikeMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($spikeMapper);
$outlineActor->GetProperty->SetColor(0.0,0.0,0.0);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($plateActor);
$ren1->AddActor($outlineActor);
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
#renWin SetFileName "vib.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
