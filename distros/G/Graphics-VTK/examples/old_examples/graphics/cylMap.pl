#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Generate texture coordinates on a "random" sphere.
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# create some random points in a sphere
$sphere = Graphics::VTK::PointSource->new;
$sphere->SetNumberOfPoints(25);
# triangulate the points
$del = Graphics::VTK::Delaunay3D->new;
$del->SetInput($sphere->GetOutput);
$del->SetTolerance(0.01);
# texture map the sphere (using cylindrical coordinate system)
$tmapper = Graphics::VTK::TextureMapToCylinder->new;
$tmapper->SetInput($del->GetOutput);
$tmapper->PreventSeamOn;
$xform = Graphics::VTK::TransformTextureCoords->new;
$xform->SetInput($tmapper->GetOutput);
$xform->SetScale(4,4,1);
$mapper = Graphics::VTK::DataSetMapper->new;
$mapper->SetInput($xform->GetOutput);
# load in the texture map and assign to actor
$bmpReader = Graphics::VTK::BMPReader->new;
$bmpReader->SetFileName("$VTK_DATA/masonry.bmp");
$atext = Graphics::VTK::Texture->new;
$atext->SetInput($bmpReader->GetOutput);
$atext->InterpolateOn;
$triangulation = Graphics::VTK::Actor->new;
$triangulation->SetMapper($mapper);
$triangulation->SetTexture($atext);
# Create rendering stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($triangulation);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$renWin->Render;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
$renWin->SetFileName("valid/cylMap.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
