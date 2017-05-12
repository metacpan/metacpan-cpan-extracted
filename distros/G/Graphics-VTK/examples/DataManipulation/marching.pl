#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates the use of the vtkTransformPolyDataFilter
# to reposition a 3D text string.


# First we include the VTK Tcl packages which will make available
# all of the vtk commands to Tcl

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;

#define a Single Cube
$Scalars = Graphics::VTK::FloatArray->new;
$Scalars->InsertNextValue(1.0);
$Scalars->InsertNextValue(0.0);
$Scalars->InsertNextValue(0.0);
$Scalars->InsertNextValue(1.0);
$Scalars->InsertNextValue(0.0);
$Scalars->InsertNextValue(0.0);
$Scalars->InsertNextValue(0.0);
$Scalars->InsertNextValue(0.0);

$Points = Graphics::VTK::Points->new;
$Points->InsertNextPoint(0,0,0);
$Points->InsertNextPoint(1,0,0);
$Points->InsertNextPoint(1,1,0);
$Points->InsertNextPoint(0,1,0);
$Points->InsertNextPoint(0,0,1);
$Points->InsertNextPoint(1,0,1);
$Points->InsertNextPoint(1,1,1);
$Points->InsertNextPoint(0,1,1);

$Ids = Graphics::VTK::IdList->new;
$Ids->InsertNextId(0);
$Ids->InsertNextId(1);
$Ids->InsertNextId(2);
$Ids->InsertNextId(3);
$Ids->InsertNextId(4);
$Ids->InsertNextId(5);
$Ids->InsertNextId(6);
$Ids->InsertNextId(7);

$Grid = Graphics::VTK::UnstructuredGrid->new;
$Grid->Allocate(10,10);
$Grid->InsertNextCell(12,$Ids);
$Grid->SetPoints($Points);
$Grid->GetPointData->SetScalars($Scalars);

# Find the triangles that lie along the 0.5 contour in this cube.
$Marching = Graphics::VTK::ContourFilter->new;
$Marching->SetInput($Grid);
$Marching->SetValue(0,0.5);
$Marching->Update;

# Extract the edges of the triangles just found.
$triangleEdges = Graphics::VTK::ExtractEdges->new;
$triangleEdges->SetInput($Marching->GetOutput);
# Draw the edges as tubes instead of lines.  Also create the associated
# mapper and actor to display the tubes.
$triangleEdgeTubes = Graphics::VTK::TubeFilter->new;
$triangleEdgeTubes->SetInput($triangleEdges->GetOutput);
$triangleEdgeTubes->SetRadius('.005');
$triangleEdgeTubes->SetNumberOfSides(6);
$triangleEdgeTubes->UseDefaultNormalOn;
$triangleEdgeTubes->SetDefaultNormal('.577','.577','.577');
$triangleEdgeMapper = Graphics::VTK::PolyDataMapper->new;
$triangleEdgeMapper->SetInput($triangleEdgeTubes->GetOutput);
$triangleEdgeMapper->ScalarVisibilityOff;
$triangleEdgeActor = Graphics::VTK::Actor->new;
$triangleEdgeActor->SetMapper($triangleEdgeMapper);
$triangleEdgeActor->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::lamp_black);
$triangleEdgeActor->GetProperty->SetSpecular('.4');
$triangleEdgeActor->GetProperty->SetSpecularPower(10);

# Shrink the triangles we found earlier.  Create the associated mapper
# and actor.  Set the opacity of the shrunken triangles.
$aShrinker = Graphics::VTK::ShrinkPolyData->new;
$aShrinker->SetShrinkFactor(1);
$aShrinker->SetInput($Marching->GetOutput);
$aMapper = Graphics::VTK::PolyDataMapper->new;
$aMapper->ScalarVisibilityOff;
$aMapper->SetInput($aShrinker->GetOutput);
$Triangles = Graphics::VTK::Actor->new;
$Triangles->SetMapper($aMapper);
$Triangles->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::banana);
$Triangles->GetProperty->SetOpacity('.6');

# Draw a cube the same size and at the same position as the one created
# previously.  Extract the edges because we only want to see the outline
# of the cube.  Pass the edges through a vtkTubeFilter so they are displayed
# as tubes rather than lines.
$CubeModel = Graphics::VTK::CubeSource->new;
$CubeModel->SetCenter('.5','.5','.5');
$Edges = Graphics::VTK::ExtractEdges->new;
$Edges->SetInput($CubeModel->GetOutput);
$Tubes = Graphics::VTK::TubeFilter->new;
$Tubes->SetInput($Edges->GetOutput);
$Tubes->SetRadius('.01');
$Tubes->SetNumberOfSides(6);
$Tubes->UseDefaultNormalOn;
$Tubes->SetDefaultNormal('.577','.577','.577');
# Create the mapper and actor to display the cube edges.
$TubeMapper = Graphics::VTK::PolyDataMapper->new;
$TubeMapper->SetInput($Tubes->GetOutput);
$CubeEdges = Graphics::VTK::Actor->new;
$CubeEdges->SetMapper($TubeMapper);
$CubeEdges->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::khaki);
$CubeEdges->GetProperty->SetSpecular('.4');
$CubeEdges->GetProperty->SetSpecularPower(10);

# Create a sphere to use as a glyph source for vtkGlyph3D.
$Sphere = Graphics::VTK::SphereSource->new;
$Sphere->SetRadius(0.04);
$Sphere->SetPhiResolution(20);
$Sphere->SetThetaResolution(20);
# Remove the part of the cube with data values below 0.5.
$ThresholdIn = Graphics::VTK::ThresholdPoints->new;
$ThresholdIn->SetInput($Grid);
$ThresholdIn->ThresholdByUpper('.5');
# Display spheres at the vertices remaining in the cube data set after
# it was passed through vtkThresholdPoints.
$Vertices = Graphics::VTK::Glyph3D->new;
$Vertices->SetInput($ThresholdIn->GetOutput);
$Vertices->SetSource($Sphere->GetOutput);
# Create a mapper and actor to display the glyphs.
$SphereMapper = Graphics::VTK::PolyDataMapper->new;
$SphereMapper->SetInput($Vertices->GetOutput);
$SphereMapper->ScalarVisibilityOff;
$CubeVertices = Graphics::VTK::Actor->new;
$CubeVertices->SetMapper($SphereMapper);
$CubeVertices->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::tomato);
$CubeVertices->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::tomato);

# Define the text for the label
$caseLabel = Graphics::VTK::VectorText->new;
$caseLabel->SetText("Case 1");

# Set up a transform to move the label to a new position.
$aLabelTransform = Graphics::VTK::Transform->new;
$aLabelTransform->Identity;
$aLabelTransform->Translate('-.2',0,1.25);
$aLabelTransform->Scale('.05','.05','.05');

# Move the label to a new position.
$labelTransform = Graphics::VTK::TransformPolyDataFilter->new;
$labelTransform->SetTransform($aLabelTransform);
$labelTransform->SetInput($caseLabel->GetOutput);

# Create a mapper and actor to display the text.
$labelMapper = Graphics::VTK::PolyDataMapper->new;
$labelMapper->SetInput($labelTransform->GetOutput);

$labelActor = Graphics::VTK::Actor->new;
$labelActor->SetMapper($labelMapper);

# Define the base that the cube sits on.  Create its associated mapper
# and actor.  Set the position of the actor.
$baseModel = Graphics::VTK::CubeSource->new;
$baseModel->SetXLength(1.5);
$baseModel->SetYLength('.01');
$baseModel->SetZLength(1.5);
$baseMapper = Graphics::VTK::PolyDataMapper->new;
$baseMapper->SetInput($baseModel->GetOutput);
$base = Graphics::VTK::Actor->new;
$base->SetMapper($baseMapper);
$base->SetPosition('.5','-.09','.5');

# Create the Renderer, RenderWindow, and RenderWindowInteractor

$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->SetSize(640,480);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the renderer
$ren1->AddActor($triangleEdgeActor);
$ren1->AddActor($base);
$ren1->AddActor($labelActor);
$ren1->AddActor($CubeEdges);
$ren1->AddActor($CubeVertices);
$ren1->AddActor($Triangles);

# Set the background color.
$ren1->SetBackground(@Graphics::VTK::Colors::slate_grey);

# Set the user method (bound to key 'u')
$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);

# Set the scalar values for this case of marching cubes.
case12($Scalars,0,1);
# Force the grid to update.
$Grid->Modified;

# Position the camera.
$ren1->GetActiveCamera->Dolly(1.2);
$ren1->GetActiveCamera->Azimuth(30);
$ren1->GetActiveCamera->Elevation(20);
$ren1->ResetCameraClippingRange;

# Render
$renWin->Render;

# Set the user method (bound to key 'u')
$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;

# Withdraw the default tk window.
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;


sub case12
{
 my $scalars = shift;
 my $IN = shift;
 my $OUT = shift;
 $scalars->InsertComponent(0,0,$OUT);
 $scalars->InsertComponent(1,0,$IN);
 $scalars->InsertComponent(2,0,$OUT);
 $scalars->InsertComponent(3,0,$IN);
 $scalars->InsertComponent(4,0,$IN);
 $scalars->InsertComponent(5,0,$IN);
 $scalars->InsertComponent(6,0,$OUT);
 $scalars->InsertComponent(7,0,$OUT);
 if ($IN == 1)
  {
   $caseLabel->SetText("Case 12 - 00111010");
  }
 else
  {
   $caseLabel->SetText("Case 12c - 11000101");
  }
}
