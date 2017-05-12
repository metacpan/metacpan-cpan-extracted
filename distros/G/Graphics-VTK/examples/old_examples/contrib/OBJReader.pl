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
# read data
$wavefront = Graphics::VTK::OBJReader->new;
$wavefront->SetFileName("$VTK_DATA/Viewpoint/cow.obj");
$wavefront->Update;
$cone = Graphics::VTK::ConeSource->new;
$cone->SetResolution(6);
$cone->SetRadius('.1');
$transform = Graphics::VTK::Transform->new;
$transform->Translate(0.5,0.0,0.0);
$transformF = Graphics::VTK::TransformPolyDataFilter->new;
$transformF->SetInput($cone->GetOutput);
$transformF->SetTransform($transform);
# we just clean the normals for efficiency (keep down number of cones)
$clean = Graphics::VTK::CleanPolyData->new;
$clean->SetInput($wavefront->GetOutput);
$glyph = Graphics::VTK::Glyph3D->new;
$glyph->SetInput($clean->GetOutput);
$glyph->SetSource($transformF->GetOutput);
$glyph->SetVectorModeToUseNormal;
$glyph->SetScaleModeToScaleByVector;
$glyph->SetScaleFactor(0.4);
$hairMapper = Graphics::VTK::PolyDataMapper->new;
$hairMapper->SetInput($glyph->GetOutput);
$hair = Graphics::VTK::Actor->new;
$hair->SetMapper($hairMapper);
$cowMapper = Graphics::VTK::PolyDataMapper->new;
$cowMapper->SetInput($wavefront->GetOutput);
$cow = Graphics::VTK::Actor->new;
$cow->SetMapper($cowMapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($cow);
$ren1->AddActor($hair);
$ren1->GetActiveCamera->Dolly(2);
$ren1->GetActiveCamera->Azimuth(30);
$ren1->GetActiveCamera->Elevation(30);
$ren1->ResetCameraClippingRange;
$hair->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::saddle_brown);
$cow->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::beige);
$renWin->SetSize(320,240);
$ren1->SetBackground('.1','.2','.4');
$iren->Initialize;
$renWin->Render;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
#renWin SetFileName OBJReader.tcl.ppm
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
