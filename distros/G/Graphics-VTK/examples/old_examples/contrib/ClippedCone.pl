#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$cone = Graphics::VTK::ConeSource->new;
$cone->SetResolution(50);
$coneMapper = Graphics::VTK::PolyDataMapper->new;
$coneMapper->SetInput($cone->GetOutput);
$coneMapper->GlobalImmediateModeRenderingOn;
$coneActor = Graphics::VTK::Actor->new;
$coneActor->SetMapper($coneMapper);
$coneActor->GetProperty->SetDiffuseColor(1,1,1);
$plane = Graphics::VTK::Plane->new;
$plane->SetOrigin(0,0,0);
$plane->SetNormal(-1,0,0);
$clipper = Graphics::VTK::ClipPolyData->new;
$clipper->SetInput($cone->GetOutput);
$clipper->SetClipFunction($plane);
$clipper->GenerateClipScalarsOn;
$clipper->GenerateClippedOutputOn;
$clipper->SetValue(0);
$clipMapper = Graphics::VTK::PolyDataMapper->new;
$clipMapper->SetInput($clipper->GetClippedOutput);
$clipMapper->ScalarVisibilityOff;
$backProp = Graphics::VTK::Property->new;
$backProp->SetDiffuseColor(@Graphics::VTK::Colors::tomato);
$clipActor = Graphics::VTK::Actor->new;
$clipActor->SetMapper($clipMapper);
$clipActor->GetProperty->SetColor(@Graphics::VTK::Colors::peacock);
$clipActor->SetBackfaceProperty($backProp);
$ren1->AddActor($clipActor);
# Create polygons outlining clipped areas and triangulate them to generate cut surface
$cutEdges = Graphics::VTK::Cutter->new;
#Generate cut lines
$cutEdges->SetInput($cone->GetOutput);
$cutEdges->SetCutFunction($plane);
$cutEdges->GenerateCutScalarsOn;
$cutEdges->SetValue(0,0);
$cutStrips = Graphics::VTK::Stripper->new;
#Forms loops (closed polylines) from cutter
$cutStrips->SetInput($cutEdges->GetOutput);
$cutStrips->Update;
$cutPoly = Graphics::VTK::PolyData->new;
#This trick defines polygons as polyline loop
$cutPoly->SetPoints($cutStrips->GetOutput->GetPoints);
$cutPoly->SetPolys($cutStrips->GetOutput->GetLines);
$cutTriangles = Graphics::VTK::TriangleFilter->new;
#Triangulates the polygons to create cut surface
$cutTriangles->SetInput($cutPoly);
$coneAppend = Graphics::VTK::AppendPolyData->new;
$coneAppend->AddInput($clipper->GetClippedOutput);
$coneAppend->AddInput($cutTriangles->GetOutput);
$cutMapper = Graphics::VTK::PolyDataMapper->new;
$cutMapper->SetInput($coneAppend->GetOutput);
$cutActor = Graphics::VTK::Actor->new;
$cutActor->SetMapper($cutMapper);
$cutActor->GetProperty->SetColor(@Graphics::VTK::Colors::peacock);
$ren1->AddActor($cutActor);
$ren1->AddActor($coneActor);
$coneActor->SetPosition(0,-1,0);
$cone1Mass = Graphics::VTK::MassProperties->new;
$cone1Mass->SetInput($coneAppend->GetOutput);
#  puts "[cone1Mass Print]"
$ren1->SetBackground('.4','.2','.1');
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$cam1 = $ren1->GetActiveCamera;
$cam1->Azimuth(-30);
$cam1->Elevation(-30);
$ren1->ResetCameraClippingRange;
$renWin->Render;
#renWin SetFileName "ClippedCone.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
