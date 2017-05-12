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
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# construct simple pixmap with test scalars
$plane = Graphics::VTK::StructuredPoints->new;
$plane->SetDimensions(3,3,1);
$scalars = Graphics::VTK::Scalars->new;
$scalars->InsertScalar(0,0.0);
$scalars->InsertScalar(1,1.0);
$scalars->InsertScalar(2,0.0);
$scalars->InsertScalar(3,1.0);
$scalars->InsertScalar(4,2.0);
$scalars->InsertScalar(5,1.0);
$scalars->InsertScalar(6,0.0);
$scalars->InsertScalar(7,1.0);
$scalars->InsertScalar(8,0.0);
$plane->GetPointData->SetScalars($scalars);
# read in texture map
$tmap = Graphics::VTK::StructuredPointsReader->new;
$tmap->SetFileName("$VTK_DATA/texThres2.vtk");
$texture = Graphics::VTK::Texture->new;
$texture->SetInput($tmap->GetOutput);
$texture->InterpolateOff;
$texture->RepeatOff;
# Cut data with texture
$planePolys = Graphics::VTK::StructuredPointsGeometryFilter->new;
$planePolys->SetInput($plane);
$planePolys->SetExtent(0,3,0,3,0,0);
$thresh = Graphics::VTK::ThresholdTextureCoords->new;
#    thresh SetInput plane
$thresh->SetInput($planePolys->GetOutput);
$thresh->ThresholdByUpper(0.5);
$planeMap = Graphics::VTK::DataSetMapper->new;
$planeMap->SetInput($thresh->GetOutput);
$planeMap->SetScalarRange(0,2);
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($planeMap);
$planeActor->SetTexture($texture);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($planeActor);
$ren1->SetBackground(0.5,0.5,0.5);
$renWin->SetSize(450,450);
#renWin SetFileName "testTexThres.tcl.ppm"
#renWin SaveImageAsPPM
$iren->Initialize;
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
