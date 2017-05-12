#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This example demonstrates the use of the linear extrusion filter and
# the USA state outline vtk dataset. It also tests the triangulation filter.
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create pipeline - read data
$reader = Graphics::VTK::PolyDataReader->new;
$reader->SetFileName("$VTK_DATA/usa.vtk");
# okay, now create some extrusion filters with actors for each US state
$math = Graphics::VTK::Math->new;
for ($i = 0; $i < 51; $i += 1)
 {
  $extractCell{$i} = Graphics::VTK::GeometryFilter->new;
  $extractCell{$i}->SetInput($reader->GetOutput);
  $extractCell{$i}->CellClippingOn;
  $extractCell{$i}->SetCellMinimum($i);
  $extractCell{$i}->SetCellMaximum($i);
  $tf{$i} = Graphics::VTK::TriangleFilter->new;
  $tf{$i}->SetInput($extractCell{$i}->GetOutput);
  $extrude{$i} = Graphics::VTK::LinearExtrusionFilter->new;
  $extrude{$i}->SetInput($tf{$i}->GetOutput);
  $extrude{$i}->SetExtrusionType(1);
  $extrude{$i}->SetVector(0,0,1);
  $extrude{$i}->CappingOn;
  $extrude{$i}->SetScaleFactor($math->Random(1,10));
  $mapper{$i} = Graphics::VTK::PolyDataMapper->new;
  $mapper{$i}->SetInput($extrude{$i}->GetOutput);
  $actor{$i} = Graphics::VTK::Actor->new;
  $actor{$i}->SetMapper($mapper{$i});
  $actor{$i}->GetProperty->SetColor(@Graphics::VTK::Colors::math->Random(0,1),$math->Random(0,1),$math->Random(0,1));
  $ren1->AddActor($actor{$i});
 }
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,250);
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(10.2299,511.497);
$cam1->SetPosition(-119.669,-25.5502,79.0198);
$cam1->SetFocalPoint(-115.96,41.6709,1.99546);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(-0.0013035,0.753456,0.657497);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
$renWin->SetFileName("eleState.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
