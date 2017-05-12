#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Demonstrate the use of clipping and capping on polyhedral data
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# create a sphere and clip it
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetRadius(1);
$sphere->SetPhiResolution(10);
$sphere->SetThetaResolution(10);
$plane = Graphics::VTK::Plane->new;
$plane->SetOrigin(0,0,0);
$plane->SetNormal(-1,-1,0);
$clipper = Graphics::VTK::ClipPolyData->new;
$clipper->SetInput($sphere->GetOutput);
$clipper->SetClipFunction($plane);
$clipper->GenerateClipScalarsOn;
$clipper->GenerateClippedOutputOn;
$clipper->SetValue(0);
$clipMapper = Graphics::VTK::PolyDataMapper->new;
$clipMapper->SetInput($clipper->GetOutput);
$clipMapper->ScalarVisibilityOff;
$backProp = Graphics::VTK::Property->new;
$backProp->SetDiffuseColor(@Graphics::VTK::Colors::tomato);
$clipActor = Graphics::VTK::Actor->new;
$clipActor->SetMapper($clipMapper);
$clipActor->GetProperty->SetColor(@Graphics::VTK::Colors::peacock);
$clipActor->SetBackfaceProperty($backProp);
# now extract feature edges
$boundaryEdges = Graphics::VTK::FeatureEdges->new;
$boundaryEdges->SetInput($clipper->GetOutput);
$boundaryEdges->BoundaryEdgesOn;
$boundaryEdges->FeatureEdgesOff;
$boundaryEdges->NonManifoldEdgesOff;
$boundaryClean = Graphics::VTK::CleanPolyData->new;
$boundaryClean->SetInput($boundaryEdges->GetOutput);
$boundaryStrips = Graphics::VTK::Stripper->new;
$boundaryStrips->SetInput($boundaryClean->GetOutput);
$boundaryStrips->Update;
$boundaryPoly = Graphics::VTK::PolyData->new;
$boundaryPoly->SetPoints($boundaryStrips->GetOutput->GetPoints);
$boundaryPoly->SetPolys($boundaryStrips->GetOutput->GetLines);
$boundaryTriangles = Graphics::VTK::TriangleFilter->new;
$boundaryTriangles->SetInput($boundaryPoly);
$boundaryMapper = Graphics::VTK::PolyDataMapper->new;
$boundaryMapper->SetInput($boundaryPoly);
$boundaryActor = Graphics::VTK::Actor->new;
$boundaryActor->SetMapper($boundaryMapper);
$boundaryActor->GetProperty->SetColor(@Graphics::VTK::Colors::banana);
# Create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($clipActor);
$ren1->AddActor($boundaryActor);
$ren1->SetBackground(1,1,1);
$ren1->GetActiveCamera->Azimuth(30);
$ren1->GetActiveCamera->Elevation(30);
$ren1->GetActiveCamera->Dolly(1.2);
$ren1->ResetCameraClippingRange;
$renWin->SetSize(400,400);
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
#renWin SetFileName "capSphere.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
