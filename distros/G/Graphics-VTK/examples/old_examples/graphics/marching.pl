#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# include get the vtk interactor ui
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# create camera figure
use Graphics::VTK::Tk::vtkInt;
#source $VTK_TCL/vtkInclude.tcl
# get some good color definitions
use Graphics::VTK::Colors;
# get the procs that define the marching cubes cases
$source->mccases_tcl;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
#define a Single Cube
$Scalars = Graphics::VTK::Scalars->new;
$Scalars->InsertNextScalar(1.0);
$Scalars->InsertNextScalar(0.0);
$Scalars->InsertNextScalar(0.0);
$Scalars->InsertNextScalar(1.0);
$Scalars->InsertNextScalar(0.0);
$Scalars->InsertNextScalar(0.0);
$Scalars->InsertNextScalar(0.0);
$Scalars->InsertNextScalar(0.0);
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
#extract the triangles for the cube
$Marching = Graphics::VTK::ContourFilter->new;
$Marching->SetInput($Grid);
$Marching->SetValue(0,0.5);
$Marching->Update;
# build tubes for the triangle edges
$triangleEdges = Graphics::VTK::ExtractEdges->new;
$triangleEdges->SetInput($Marching->GetOutput);
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
$ren1->AddActor($triangleEdgeActor);
#shrink the triangles so we can see each one
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
#build a model of the cube
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
$TubeMapper = Graphics::VTK::PolyDataMapper->new;
$TubeMapper->SetInput($Tubes->GetOutput);
$CubeEdges = Graphics::VTK::Actor->new;
$CubeEdges->SetMapper($TubeMapper);
$CubeEdges->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::khaki);
$CubeEdges->GetProperty->SetSpecular('.4');
$CubeEdges->GetProperty->SetSpecularPower(10);
# build the vertices of the cube
$Sphere = Graphics::VTK::SphereSource->new;
$Sphere->SetRadius(0.04);
$Sphere->SetPhiResolution(20);
$Sphere->SetThetaResolution(20);
$ThresholdIn = Graphics::VTK::ThresholdPoints->new;
$ThresholdIn->SetInput($Grid);
$ThresholdIn->ThresholdByUpper('.5');
$Vertices = Graphics::VTK::Glyph3D->new;
$Vertices->SetInput($ThresholdIn->GetOutput);
$Vertices->SetSource($Sphere->GetOutput);
$SphereMapper = Graphics::VTK::PolyDataMapper->new;
$SphereMapper->SetInput($Vertices->GetOutput);
$SphereMapper->ScalarVisibilityOff;
$CubeVertices = Graphics::VTK::Actor->new;
$CubeVertices->SetMapper($SphereMapper);
$CubeVertices->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::tomato);
$CubeVertices->GetProperty->SetDiffuseColor(@Graphics::VTK::Colors::tomato);
#define the text for the labels
$caseLabel = Graphics::VTK::VectorText->new;
$caseLabel->SetText("Case 1");
$aLabelTransform = Graphics::VTK::Transform->new;
$aLabelTransform->Identity;
$aLabelTransform->Translate('-.2',0,1.25);
$aLabelTransform->Scale('.05','.05','.05');
$labelTransform = Graphics::VTK::TransformPolyDataFilter->new;
$labelTransform->SetTransform($aLabelTransform);
$labelTransform->SetInput($caseLabel->GetOutput);
$labelMapper = Graphics::VTK::PolyDataMapper->new;
$labelMapper->SetInput($labelTransform->GetOutput);
$labelActor = Graphics::VTK::Actor->new;
$labelActor->SetMapper($labelMapper);
#define the base 
$baseModel = Graphics::VTK::CubeSource->new;
$baseModel->SetXLength(1.5);
$baseModel->SetYLength('.01');
$baseModel->SetZLength(1.5);
$baseMapper = Graphics::VTK::PolyDataMapper->new;
$baseMapper->SetInput($baseModel->GetOutput);
$base = Graphics::VTK::Actor->new;
$base->SetMapper($baseMapper);
# position the base
$base->SetPosition('.5','-.09','.5');
$ren1->AddActor($base);
$ren1->AddActor($labelActor);
$ren1->AddActor($CubeEdges);
$ren1->AddActor($CubeVertices);
$ren1->AddActor($Triangles);
$ren1->SetBackground($slate_grey);
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$case12->_Scalars(0,1);
$Grid->Modified;
$renWin->SetStereoType(1);
$renWin->SetSize(640,480);
$ren1->GetActiveCamera->Dolly(1.2);
$ren1->GetActiveCamera->Azimuth(30);
$ren1->GetActiveCamera->Elevation(20);
$ren1->ResetCameraClippingRange;
$renWin->Render;
$iren->Initialize;
# get the user interface to select the cases
# if we are not running regression tests
if (!defined($rtExMath))
 {
  $source->mccasesui_tcl;
 }
else
 {
  $MW->withdraw;
 }
#renWin SetFileName marching.tcl.ppm
#renWin SaveImageAsPPM
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
