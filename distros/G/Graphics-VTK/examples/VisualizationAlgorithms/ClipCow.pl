#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# In this example vtkClipPolyData is used to cut a polygonal model
# of a cow in half. In addition, the open clip is closed by triangulating
# the resulting complex polygons.

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;

# First start by reading a cow model. We also generate surface normals for
# prettier rendering.
$cow = Graphics::VTK::BYUReader->new;
$cow->SetGeometryFileName("$VTK_DATA_ROOT/Data/Viewpoint/cow.g");
$cowNormals = Graphics::VTK::PolyDataNormals->new;
$cowNormals->SetInput($cow->GetOutput);

# We clip with an implicit function. Here we use a plane positioned near
# the center of the cow model and oriented at an arbitrary angle.
$plane = Graphics::VTK::Plane->new;
$plane->SetOrigin(0.25,0,0);
$plane->SetNormal(-1,-1,0);

# vtkClipPolyData requires an implicit function to define what it is to
# clip with. Any implicit function, including complex boolean combinations
# can be used. Notice that we can specify the value of the implicit function
# with the SetValue method.
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

# Here we are cutting the cow. Cutting creates lines where the cut function
# intersects the model. (Clipping removes a portion of the model but the
# dimension of the data does not change.)

# The reason we are cutting is to generate a closed polygon at the boundary
# of the clipping process. The cutter generates line segments, the stripper
# then puts them together into polylines. We then pull a trick and define
# polygons using the closed line segements that the stripper created.

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

# Triangle filter is robust enough to ignore the duplicate point at the 
# beginning and end of the polygons and triangulate them.
$cutTriangles = Graphics::VTK::TriangleFilter->new;
$cutTriangles->SetInput($cutPoly);
$cutMapper = Graphics::VTK::PolyDataMapper->new;
$cutMapper->SetInput($cutPoly);
$cutMapper->SetInput($cutTriangles->GetOutput);
$cutActor = Graphics::VTK::Actor->new;
$cutActor->SetMapper($cutMapper);
$cutActor->GetProperty->SetColor(@Graphics::VTK::Colors::peacock);

# The clipped part of the cow is rendered wireframe.
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

$renWin->SetSize(300,300);
$iren->Initialize;

# render the image

$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);

# prevent the tk window from showing up then start the event loop
$MW->withdraw;

# Lets you move the cut plane back and forth by invoking the proc Cut with
# the appropriate plane value (essentially a distance from the original
# plane.

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
