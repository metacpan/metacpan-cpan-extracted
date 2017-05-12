#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Demonstrate the use of clipping and capping on polyhedral data. Also shows how to
# use triangle filter to triangulate loops.
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# create pipeline
# Read the polygonal data and generate vertex normals
$cow = Graphics::VTK::BYUReader->new;
$cow->SetGeometryFileName("$VTK_DATA/Viewpoint/cow.g");
$cowNormals = Graphics::VTK::PolyDataNormals->new;
$cowNormals->SetInput($cow->GetOutput);
# Define a clip plane to clip the cow in half
$plane = Graphics::VTK::Plane->new;
$plane->SetOrigin(0.25,0,0);
$plane->SetNormal(-1,-1,0);
$clipper = Graphics::VTK::ClipPolyData->new;
$clipper->SetInput($cowNormals->GetOutput);
$clipper->SetClipFunction($plane);
$clipper->GenerateClipScalarsOn;
$clipper->GenerateClippedOutputOn;
$clipper->SetValue(0.5);
$clipMapper = Graphics::VTK::PolyDataMapper->new;
$clipMapper->SetInput($clipper->GetOutput);
$clipMapper->ScalarVisibilityOff;
$backProp = Graphics::VTK::Property->new;
$backProp->SetDiffuseColor(@Graphics::VTK::Colors::tomato);
$clipActor = Graphics::VTK::Actor->new;
$clipActor->SetMapper($clipMapper);
$clipActor->GetProperty->SetColor(@Graphics::VTK::Colors::peacock);
$clipActor->SetBackfaceProperty($backProp);
# Create polygons outlining clipped areas and triangulate them to generate cut surface
$cutEdges = Graphics::VTK::Cutter->new;
#Generate cut lines
$cutEdges->SetInput($cowNormals->GetOutput);
$cutEdges->SetCutFunction($plane);
$cutEdges->GenerateCutScalarsOn;
$cutEdges->SetValue(0,0.5);
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
$cutMapper = Graphics::VTK::PolyDataMapper->new;
$cutMapper->SetInput($cutPoly);
$cutMapper->SetInput($cutTriangles->GetOutput);
$cutActor = Graphics::VTK::Actor->new;
$cutActor->SetMapper($cutMapper);
$cutActor->GetProperty->SetColor(@Graphics::VTK::Colors::peacock);
# Create the rest of the cow in wireframe
$restMapper = Graphics::VTK::PolyDataMapper->new;
$restMapper->SetInput($clipper->GetClippedOutput);
$restMapper->ScalarVisibilityOff;
$restActor = Graphics::VTK::Actor->new;
$restActor->SetMapper($restMapper);
$restActor->GetProperty->SetRepresentationToWireframe;
# Create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($clipActor);
$ren1->AddActor($cutActor);
$ren1->AddActor($restActor);
$ren1->SetBackground(1,1,1);
$ren1->GetActiveCamera->Azimuth(30);
$ren1->GetActiveCamera->Elevation(30);
$ren1->GetActiveCamera->Dolly(1.5);
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
$renWin->SetFileName("capCow.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
# Lets you move the cut plane back and forth
#
sub Cut
{
 my $v = shift;
 $clipper->SetValue($v);
 $cutEdges->SetValue(0,$v);
 $cutStrips->Update;
 $cutPoly->SetPoints($cutStrips->GetOutput->GetPoints);
 $cutPoly->SetPolys($cutStrips->GetOutput->GetLines);
 $cutMapper->Update;
 $renWin->Render;
}
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
