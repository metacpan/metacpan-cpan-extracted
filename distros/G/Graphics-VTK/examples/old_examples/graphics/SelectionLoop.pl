#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Demonstrate the use of implicit selection loop as well as closest point
# connectivity
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# create pipeline
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetRadius(1);
$sphere->SetPhiResolution(100);
$sphere->SetThetaResolution(100);
$selectionPoints = Graphics::VTK::Points->new;
$selectionPoints->InsertPoint(0,0.07325,0.8417,0.5612);
$selectionPoints->InsertPoint(1,0.07244,0.6568,0.7450);
$selectionPoints->InsertPoint(2,0.1727,0.4597,0.8850);
$selectionPoints->InsertPoint(3,0.3265,0.6054,0.7309);
$selectionPoints->InsertPoint(4,0.5722,0.5848,0.5927);
$selectionPoints->InsertPoint(5,0.4305,0.8138,0.4189);
$loop = Graphics::VTK::ImplicitSelectionLoop->new;
$loop->SetLoop($selectionPoints);
$extract = Graphics::VTK::ExtractGeometry->new;
$extract->SetInput($sphere->GetOutput);
$extract->SetImplicitFunction($loop);
$connect = Graphics::VTK::ConnectivityFilter->new;
$connect->SetInput($extract->GetOutput);
$connect->SetExtractionModeToClosestPointRegion;
$connect->SetClosestPoint($selectionPoints->GetPoint(0));
$clipMapper = Graphics::VTK::DataSetMapper->new;
$clipMapper->SetInput($connect->GetOutput);
$backProp = Graphics::VTK::Property->new;
$backProp->SetDiffuseColor(@Graphics::VTK::Colors::tomato);
$clipActor = Graphics::VTK::Actor->new;
$clipActor->SetMapper($clipMapper);
$clipActor->GetProperty->SetColor(@Graphics::VTK::Colors::peacock);
$clipActor->SetBackfaceProperty($backProp);
# Create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($clipActor);
$ren1->SetBackground(1,1,1);
$ren1->GetActiveCamera->Azimuth(30);
$ren1->GetActiveCamera->Elevation(30);
$ren1->GetActiveCamera->Dolly(1.2);
$ren1->ResetCameraClippingRange;
$renWin->SetSize(400,400);
$renWin->Render;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->SetFileName("SelectionLoop.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
