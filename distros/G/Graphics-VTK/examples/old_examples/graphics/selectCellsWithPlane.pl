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
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create a plane 
$plane = Graphics::VTK::PlaneSource->new;
$plane->SetResolution(10,10);
$halfPlane = Graphics::VTK::Plane->new;
$halfPlane->SetOrigin('-.13','-.03',0);
$halfPlane->SetNormal(1,'.2',0);
# assign scalars to points
$plane->Update;
$points = $plane->GetOutput->GetPoints;
$numPoints = $points->GetNumberOfPoints;
$scalars = Graphics::VTK::Scalars->new;
$scalars->SetNumberOfScalars($numPoints);
for ($i = 0; $i < $numPoints; $i += 1)
 {
  $scalars->SetScalar($i,$halfPlane->EvaluateFunction($points->GetPoint($i)));
 }
$plane->Update;
$plane->GetOutput->GetPointData->SetScalars($scalars);
$positive = Graphics::VTK::Threshold->new;
$positive->SetInput($plane->GetOutput);
$positive->ThresholdByUpper(0.0);
$positive->AllScalarsOff;
$negative = Graphics::VTK::Threshold->new;
$negative->SetInput($positive->GetOutput);
$negative->ThresholdByLower(0.0);
$negative->AllScalarsOff;
$planeMapper = Graphics::VTK::DataSetMapper->new;
$planeMapper->SetInput($negative->GetOutput);
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($planeMapper);
$planeActor->GetProperty->SetDiffuseColor(0,0,0);
$planeActor->GetProperty->SetRepresentationToWireframe;
# Add the actors to the renderer, set the background and size
$ren1->AddActor($planeActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(300,300);
#renWin SetFileName "selectCellsWithPlane.tcl.ppm"
#renWin SaveImageAsPPM
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
