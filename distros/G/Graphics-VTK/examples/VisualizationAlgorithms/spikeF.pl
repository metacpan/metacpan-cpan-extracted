#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates the use of glyphing. We also use a mask filter
# to select a subset of points to glyph.


# First we include the VTK Tcl packages which will make available
# all of the vtk commands from Tcl. The vtkinteraction package defines
# a simple Tcl/Tk interactor widget.

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;

# Read a data file. This originally was a Cyberware laser digitizer scan 
# of Fran J.'s face. Surface normals are generated based on local geometry
# (i.e., the polygon normals surrounding eash point are averaged). We flip
# the normals because we want them to point out from Fran's face.

$fran = Graphics::VTK::PolyDataReader->new;
$fran->SetFileName("$VTK_DATA_ROOT/Data/fran_cut.vtk");
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($fran->GetOutput);
$normals->FlipNormalsOn;
$franMapper = Graphics::VTK::PolyDataMapper->new;
$franMapper->SetInput($normals->GetOutput);
$franActor = Graphics::VTK::Actor->new;
$franActor->SetMapper($franMapper);
$franActor->GetProperty->SetColor(1.0,0.49,0.25);

# We subsample the dataset because we want to glyph just a subset of
# the points. Otherwise the display is cluttered and cannot be easily
# read. The RandonModeOn and SetOnRatio combine to random select one out
# of every 10 points in the dataset.

$ptMask = Graphics::VTK::MaskPoints->new;
$ptMask->SetInput($normals->GetOutput);
$ptMask->SetOnRatio(10);
$ptMask->RandomModeOn;

# In this case we are using a cone as a glyph. We transform the cone so
# its base is at 0,0,0. This is the point where glyph rotation occurs.
$cone = Graphics::VTK::ConeSource->new;
$cone->SetResolution(6);
$transform = Graphics::VTK::Transform->new;
$transform->Translate(0.5,0.0,0.0);
$transformF = Graphics::VTK::TransformPolyDataFilter->new;
$transformF->SetInput($cone->GetOutput);
$transformF->SetTransform($transform);

# vtkGlyph3D takes two inputs: the input point set (SetInput) which can be
# any vtkDataSet; and the glyph (SetSource) which must be a vtkPolyData.
# We are interested in orienting the glyphs by the surface normals that
# we previosuly generated.
$glyph = Graphics::VTK::Glyph3D->new;
$glyph->SetInput($ptMask->GetOutput);
$glyph->SetSource($transformF->GetOutput);
$glyph->SetVectorModeToUseNormal;
$glyph->SetScaleModeToScaleByVector;
$glyph->SetScaleFactor(0.004);
$spikeMapper = Graphics::VTK::PolyDataMapper->new;
$spikeMapper->SetInput($glyph->GetOutput);
$spikeActor = Graphics::VTK::Actor->new;
$spikeActor->SetMapper($spikeMapper);
$spikeActor->GetProperty->SetColor(0.0,0.79,0.34);

# Create the RenderWindow, Renderer and both Actors

$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the renderer, set the background and size

$ren1->AddActor($franActor);
$ren1->AddActor($spikeActor);

$renWin->SetSize(500,500);
$ren1->SetBackground(0.1,0.2,0.4);

# render the image

$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;

$cam1 = $ren1->GetActiveCamera;
$cam1->Zoom(1.4);
$cam1->Azimuth(110);
$iren->Initialize;

# prevent the tk window from showing up then start the event loop
$MW->withdraw;


Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
