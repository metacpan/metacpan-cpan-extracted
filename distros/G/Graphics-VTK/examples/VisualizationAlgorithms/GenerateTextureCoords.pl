#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example shows how to generate and manipulate texture coordinates.
# A random cloud of points is generated and then triangulated with 
# vtkDelaunay3D. Since these points do not have texture coordinates,
# we generate them with vtkTextureMapToCylinder.

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};

# Begin by generating 25 random points in the unit sphere.

$sphere = Graphics::VTK::PointSource->new;
$sphere->SetNumberOfPoints(25);

# Triangulate the points with vtkDelaunay3D. This generates a convex hull
# of tetrahedron.

$del = Graphics::VTK::Delaunay3D->new;
$del->SetInput($sphere->GetOutput);
$del->SetTolerance(0.01);

# The triangulation has texture coordinates generated so we can map
# a texture onto it.

$tmapper = Graphics::VTK::TextureMapToCylinder->new;
$tmapper->SetInput($del->GetOutput);
$tmapper->PreventSeamOn;

# We scale the texture coordinate to get some repeat patterns.
$xform = Graphics::VTK::TransformTextureCoords->new;
$xform->SetInput($tmapper->GetOutput);
$xform->SetScale(4,4,1);

# vtkDataSetMapper internally uses a vtkGeometryFilter to extract the
# surface from the trinagulation. The output (which is vtkPolyData) is
# then passed to an internal vtkPolyDataMapper which does the
# rendering.
$mapper = Graphics::VTK::DataSetMapper->new;
$mapper->SetInput($xform->GetOutput);

# A texture is loaded using an image reader. Textures are simply images.
# The texture is eventually associated with an actor.

$bmpReader = Graphics::VTK::BMPReader->new;
$bmpReader->SetFileName("$VTK_DATA_ROOT/Data/masonry.bmp");
$atext = Graphics::VTK::Texture->new;
$atext->SetInput($bmpReader->GetOutput);
$atext->InterpolateOn;
$triangulation = Graphics::VTK::Actor->new;
$triangulation->SetMapper($mapper);
$triangulation->SetTexture($atext);

# Create the standard rendering stuff.
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the renderer, set the background and size

$ren1->AddActor($triangulation);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(300,300);
$renWin->Render;

# render the image

$renWin->Render;

# prevent the tk window from showing up then start the event loop
$MW->withdraw;




Tk->MainLoop;
