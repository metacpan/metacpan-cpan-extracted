#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# clip a textured plane
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
# Create a plane source
$plane = Graphics::VTK::PlaneSource->new;
$aTransform = Graphics::VTK::Transform->new;
$aTransform->RotateX(30);
$aTransform->RotateY(30);
$transformPlane = Graphics::VTK::TransformPolyDataFilter->new;
$transformPlane->SetInput($plane->GetOutput);
$transformPlane->SetTransform($aTransform);
$clipPlane1 = Graphics::VTK::Plane->new;
$clipPlane1->SetNormal(0,0,1);
$planeMapper = Graphics::VTK::DataSetMapper->new;
$planeMapper->SetInput($transformPlane->GetOutput);
$planeMapper->AddClippingPlane($clipPlane1);
$planeActor = Graphics::VTK::Actor->new;
$planeActor->SetMapper($planeMapper);
$plane2Mapper = Graphics::VTK::DataSetMapper->new;
$plane2Mapper->SetInput($plane->GetOutput);
$plane2Actor = Graphics::VTK::Actor->new;
$plane2Actor->SetMapper($plane2Mapper);
# load in the texture map
$atext = Graphics::VTK::Texture->new;
$pnmReader = Graphics::VTK::PNMReader->new;
$pnmReader->SetFileName("$VTK_DATA/masonry.ppm");
$atext->SetInput($pnmReader->GetOutput);
$atext->InterpolateOn;
$planeActor->SetTexture($atext);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($planeActor);
$ren1->AddActor($plane2Actor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(500,500);
# render the image
$iren->Initialize;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
$cam1 = $ren1->GetActiveCamera;
$cam1->Elevation(-30);
$cam1->Roll(-20);
$renWin->Render;
#renWin SetFileName "clipTexPlane.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
