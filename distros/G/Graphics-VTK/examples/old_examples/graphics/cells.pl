#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Demonstrates all cell types
# NOTE: the use of MakeObject is included to increase regression coverage.
# It is not required in most applications.
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create a scene with one of each cell type
$voxelPoints = Graphics::VTK::Points->new;
$voxelPoints->SetNumberOfPoints(8);
$voxelPoints->InsertPoint(0,0,0,0);
$voxelPoints->InsertPoint(1,1,0,0);
$voxelPoints->InsertPoint(2,0,1,0);
$voxelPoints->InsertPoint(3,1,1,0);
$voxelPoints->InsertPoint(4,0,0,1);
$voxelPoints->InsertPoint(5,1,0,1);
$voxelPoints->InsertPoint(6,0,1,1);
$voxelPoints->InsertPoint(7,1,1,1);
$aVoxel = Graphics::VTK::Voxel->new;
$aVoxel->GetPointIds->SetId(0,0);
$aVoxel->GetPointIds->SetId(1,1);
$aVoxel->GetPointIds->SetId(2,2);
$aVoxel->GetPointIds->SetId(3,3);
$aVoxel->GetPointIds->SetId(4,4);
$aVoxel->GetPointIds->SetId(5,5);
$aVoxel->GetPointIds->SetId(6,6);
$aVoxel->GetPointIds->SetId(7,7);
$bVoxel = $aVoxel->MakeObject;
$aVoxelGrid = Graphics::VTK::UnstructuredGrid->new;
$aVoxelGrid->Allocate(1,1);
$aVoxelGrid->InsertNextCell($aVoxel->GetCellType,$aVoxel->GetPointIds);
$aVoxelGrid->SetPoints($voxelPoints);
$aVoxelMapper = Graphics::VTK::DataSetMapper->new;
$aVoxelMapper->SetInput($aVoxelGrid);
$aVoxelActor = Graphics::VTK::Actor->new;
$aVoxelActor->SetMapper($aVoxelMapper);
$aVoxelActor->GetProperty->BackfaceCullingOn;
$hexahedronPoints = Graphics::VTK::Points->new;
$hexahedronPoints->SetNumberOfPoints(8);
$hexahedronPoints->InsertPoint(0,0,0,0);
$hexahedronPoints->InsertPoint(1,1,0,0);
$hexahedronPoints->InsertPoint(2,1,1,0);
$hexahedronPoints->InsertPoint(3,0,1,0);
$hexahedronPoints->InsertPoint(4,0,0,1);
$hexahedronPoints->InsertPoint(5,1,0,1);
$hexahedronPoints->InsertPoint(6,1,1,1);
$hexahedronPoints->InsertPoint(7,0,1,1);
$aHexahedron = Graphics::VTK::Hexahedron->new;
$aHexahedron->GetPointIds->SetId(0,0);
$aHexahedron->GetPointIds->SetId(1,1);
$aHexahedron->GetPointIds->SetId(2,2);
$aHexahedron->GetPointIds->SetId(3,3);
$aHexahedron->GetPointIds->SetId(4,4);
$aHexahedron->GetPointIds->SetId(5,5);
$aHexahedron->GetPointIds->SetId(6,6);
$aHexahedron->GetPointIds->SetId(7,7);
$bHexahedron = $aHexahedron->MakeObject;
$aHexahedronGrid = Graphics::VTK::UnstructuredGrid->new;
$aHexahedronGrid->Allocate(1,1);
$aHexahedronGrid->InsertNextCell($aHexahedron->GetCellType,$aHexahedron->GetPointIds);
$aHexahedronGrid->SetPoints($hexahedronPoints);
$aHexahedronMapper = Graphics::VTK::DataSetMapper->new;
$aHexahedronMapper->SetInput($aHexahedronGrid);
$aHexahedronActor = Graphics::VTK::Actor->new;
$aHexahedronActor->SetMapper($aHexahedronMapper);
$aHexahedronActor->AddPosition(2,0,0);
$aHexahedronActor->GetProperty->BackfaceCullingOn;
$tetraPoints = Graphics::VTK::Points->new;
$tetraPoints->SetNumberOfPoints(4);
$tetraPoints->InsertPoint(0,0,0,0);
$tetraPoints->InsertPoint(1,1,0,0);
$tetraPoints->InsertPoint(2,'.5',1,0);
$tetraPoints->InsertPoint(3,'.5','.5',1);
$aTetra = Graphics::VTK::Tetra->new;
$aTetra->GetPointIds->SetId(0,0);
$aTetra->GetPointIds->SetId(1,1);
$aTetra->GetPointIds->SetId(2,2);
$aTetra->GetPointIds->SetId(3,3);
$bTetra = $aTetra->MakeObject;
$aTetraGrid = Graphics::VTK::UnstructuredGrid->new;
$aTetraGrid->Allocate(1,1);
$aTetraGrid->InsertNextCell($aTetra->GetCellType,$aTetra->GetPointIds);
$aTetraGrid->SetPoints($tetraPoints);
$aTetraMapper = Graphics::VTK::DataSetMapper->new;
$aTetraMapper->SetInput($aTetraGrid);
$aTetraActor = Graphics::VTK::Actor->new;
$aTetraActor->SetMapper($aTetraMapper);
$aTetraActor->AddPosition(4,0,0);
$aTetraActor->GetProperty->BackfaceCullingOn;
$wedgePoints = Graphics::VTK::Points->new;
$wedgePoints->SetNumberOfPoints(6);
$wedgePoints->InsertPoint(0,0,1,0);
$wedgePoints->InsertPoint(1,0,0,0);
$wedgePoints->InsertPoint(2,0,'.5','.5');
$wedgePoints->InsertPoint(3,1,1,0);
$wedgePoints->InsertPoint(4,1,0,0);
$wedgePoints->InsertPoint(5,1,'.5','.5');
$aWedge = Graphics::VTK::Wedge->new;
$aWedge->GetPointIds->SetId(0,0);
$aWedge->GetPointIds->SetId(1,1);
$aWedge->GetPointIds->SetId(2,2);
$aWedge->GetPointIds->SetId(3,3);
$aWedge->GetPointIds->SetId(4,4);
$aWedge->GetPointIds->SetId(5,5);
$bWedge = $aWedge->MakeObject;
$aWedgeGrid = Graphics::VTK::UnstructuredGrid->new;
$aWedgeGrid->Allocate(1,1);
$aWedgeGrid->InsertNextCell($aWedge->GetCellType,$aWedge->GetPointIds);
$aWedgeGrid->SetPoints($wedgePoints);
$aWedgeMapper = Graphics::VTK::DataSetMapper->new;
$aWedgeMapper->SetInput($aWedgeGrid);
$aWedgeActor = Graphics::VTK::Actor->new;
$aWedgeActor->SetMapper($aWedgeMapper);
$aWedgeActor->AddPosition(6,0,0);
$aWedgeActor->GetProperty->BackfaceCullingOn;
$pyramidPoints = Graphics::VTK::Points->new;
$pyramidPoints->SetNumberOfPoints(5);
$pyramidPoints->InsertPoint(0,0,0,0);
$pyramidPoints->InsertPoint(1,1,0,0);
$pyramidPoints->InsertPoint(2,1,1,0);
$pyramidPoints->InsertPoint(3,0,1,0);
$pyramidPoints->InsertPoint(4,'.5','.5',1);
$aPyramid = Graphics::VTK::Pyramid->new;
$aPyramid->GetPointIds->SetId(0,0);
$aPyramid->GetPointIds->SetId(1,1);
$aPyramid->GetPointIds->SetId(2,2);
$aPyramid->GetPointIds->SetId(3,3);
$aPyramid->GetPointIds->SetId(4,4);
$bPyramid = $aPyramid->MakeObject;
$aPyramidGrid = Graphics::VTK::UnstructuredGrid->new;
$aPyramidGrid->Allocate(1,1);
$aPyramidGrid->InsertNextCell($aPyramid->GetCellType,$aPyramid->GetPointIds);
$aPyramidGrid->SetPoints($pyramidPoints);
$aPyramidMapper = Graphics::VTK::DataSetMapper->new;
$aPyramidMapper->SetInput($aPyramidGrid);
$aPyramidActor = Graphics::VTK::Actor->new;
$aPyramidActor->SetMapper($aPyramidMapper);
$aPyramidActor->AddPosition(8,0,0);
$aPyramidActor->GetProperty->BackfaceCullingOn;
$pixelPoints = Graphics::VTK::Points->new;
$pixelPoints->SetNumberOfPoints(4);
$pixelPoints->InsertPoint(0,0,0,0);
$pixelPoints->InsertPoint(1,1,0,0);
$pixelPoints->InsertPoint(2,0,1,0);
$pixelPoints->InsertPoint(3,1,1,0);
$aPixel = Graphics::VTK::Pixel->new;
$aPixel->GetPointIds->SetId(0,0);
$aPixel->GetPointIds->SetId(1,1);
$aPixel->GetPointIds->SetId(2,2);
$aPixel->GetPointIds->SetId(3,3);
$bPixel = $aPixel->MakeObject;
$aPixelGrid = Graphics::VTK::UnstructuredGrid->new;
$aPixelGrid->Allocate(1,1);
$aPixelGrid->InsertNextCell($aPixel->GetCellType,$aPixel->GetPointIds);
$aPixelGrid->SetPoints($pixelPoints);
$aPixelMapper = Graphics::VTK::DataSetMapper->new;
$aPixelMapper->SetInput($aPixelGrid);
$aPixelActor = Graphics::VTK::Actor->new;
$aPixelActor->SetMapper($aPixelMapper);
$aPixelActor->AddPosition(0,0,2);
$aPixelActor->GetProperty->BackfaceCullingOn;
$quadPoints = Graphics::VTK::Points->new;
$quadPoints->SetNumberOfPoints(4);
$quadPoints->InsertPoint(0,0,0,0);
$quadPoints->InsertPoint(1,1,0,0);
$quadPoints->InsertPoint(2,1,1,0);
$quadPoints->InsertPoint(3,0,1,0);
$aQuad = Graphics::VTK::Quad->new;
$aQuad->GetPointIds->SetId(0,0);
$aQuad->GetPointIds->SetId(1,1);
$aQuad->GetPointIds->SetId(2,2);
$aQuad->GetPointIds->SetId(3,3);
$bQuad = $aQuad->MakeObject;
$aQuadGrid = Graphics::VTK::UnstructuredGrid->new;
$aQuadGrid->Allocate(1,1);
$aQuadGrid->InsertNextCell($aQuad->GetCellType,$aQuad->GetPointIds);
$aQuadGrid->SetPoints($quadPoints);
$aQuadMapper = Graphics::VTK::DataSetMapper->new;
$aQuadMapper->SetInput($aQuadGrid);
$aQuadActor = Graphics::VTK::Actor->new;
$aQuadActor->SetMapper($aQuadMapper);
$aQuadActor->AddPosition(2,0,2);
$aQuadActor->GetProperty->BackfaceCullingOn;
$trianglePoints = Graphics::VTK::Points->new;
$trianglePoints->SetNumberOfPoints(3);
$trianglePoints->InsertPoint(0,0,0,0);
$trianglePoints->InsertPoint(1,1,0,0);
$trianglePoints->InsertPoint(2,'.5','.5',0);
$triangleTCoords = Graphics::VTK::TCoords->new;
$triangleTCoords->SetNumberOfTCoords(3);
$triangleTCoords->InsertTCoord(0,1,1,1);
$triangleTCoords->InsertTCoord(1,2,2,2);
$triangleTCoords->InsertTCoord(2,3,3,3);
$aTriangle = Graphics::VTK::Triangle->new;
$aTriangle->GetPointIds->SetId(0,0);
$aTriangle->GetPointIds->SetId(1,1);
$aTriangle->GetPointIds->SetId(2,2);
$bTriangle = $aTriangle->MakeObject;
$aTriangleGrid = Graphics::VTK::UnstructuredGrid->new;
$aTriangleGrid->Allocate(1,1);
$aTriangleGrid->InsertNextCell($aTriangle->GetCellType,$aTriangle->GetPointIds);
$aTriangleGrid->SetPoints($trianglePoints);
$aTriangleGrid->GetPointData->SetTCoords($triangleTCoords);
$aTriangleMapper = Graphics::VTK::DataSetMapper->new;
$aTriangleMapper->SetInput($aTriangleGrid);
$aTriangleActor = Graphics::VTK::Actor->new;
$aTriangleActor->SetMapper($aTriangleMapper);
$aTriangleActor->AddPosition(4,0,2);
$aTriangleActor->GetProperty->BackfaceCullingOn;
$polygonPoints = Graphics::VTK::Points->new;
$polygonPoints->SetNumberOfPoints(4);
$polygonPoints->InsertPoint(0,0,0,0);
$polygonPoints->InsertPoint(1,1,0,0);
$polygonPoints->InsertPoint(2,1,1,0);
$polygonPoints->InsertPoint(3,0,1,0);
$aPolygon = Graphics::VTK::Polygon->new;
$aPolygon->GetPointIds->SetNumberOfIds(4);
$aPolygon->GetPointIds->SetId(0,0);
$aPolygon->GetPointIds->SetId(1,1);
$aPolygon->GetPointIds->SetId(2,2);
$aPolygon->GetPointIds->SetId(3,3);
$bPolygon = $aPolygon->MakeObject;
$aPolygonGrid = Graphics::VTK::UnstructuredGrid->new;
$aPolygonGrid->Allocate(1,1);
$aPolygonGrid->InsertNextCell($aPolygon->GetCellType,$aPolygon->GetPointIds);
$aPolygonGrid->SetPoints($polygonPoints);
$aPolygonMapper = Graphics::VTK::DataSetMapper->new;
$aPolygonMapper->SetInput($aPolygonGrid);
$aPolygonActor = Graphics::VTK::Actor->new;
$aPolygonActor->SetMapper($aPolygonMapper);
$aPolygonActor->AddPosition(6,0,2);
$aPolygonActor->GetProperty->BackfaceCullingOn;
$triangleStripPoints = Graphics::VTK::Points->new;
$triangleStripPoints->SetNumberOfPoints(5);
$triangleStripPoints->InsertPoint(0,0,1,0);
$triangleStripPoints->InsertPoint(1,0,0,0);
$triangleStripPoints->InsertPoint(2,1,1,0);
$triangleStripPoints->InsertPoint(3,1,0,0);
$triangleStripPoints->InsertPoint(4,2,1,0);
$triangleStripTCoords = Graphics::VTK::TCoords->new;
$triangleStripTCoords->SetNumberOfTCoords(3);
$triangleStripTCoords->InsertTCoord(0,1,1,1);
$triangleStripTCoords->InsertTCoord(1,2,2,2);
$triangleStripTCoords->InsertTCoord(2,3,3,3);
$triangleStripTCoords->InsertTCoord(3,4,4,4);
$triangleStripTCoords->InsertTCoord(4,5,5,5);
$aTriangleStrip = Graphics::VTK::TriangleStrip->new;
$aTriangleStrip->GetPointIds->SetNumberOfIds(5);
$aTriangleStrip->GetPointIds->SetId(0,0);
$aTriangleStrip->GetPointIds->SetId(1,1);
$aTriangleStrip->GetPointIds->SetId(2,2);
$aTriangleStrip->GetPointIds->SetId(3,3);
$aTriangleStrip->GetPointIds->SetId(4,4);
$bTriangleStrip = $aTriangleStrip->MakeObject;
$aTriangleStripGrid = Graphics::VTK::UnstructuredGrid->new;
$aTriangleStripGrid->Allocate(1,1);
$aTriangleStripGrid->InsertNextCell($aTriangleStrip->GetCellType,$aTriangleStrip->GetPointIds);
$aTriangleStripGrid->SetPoints($triangleStripPoints);
$aTriangleStripGrid->GetPointData->SetTCoords($triangleStripTCoords);
$aTriangleStripMapper = Graphics::VTK::DataSetMapper->new;
$aTriangleStripMapper->SetInput($aTriangleStripGrid);
$aTriangleStripActor = Graphics::VTK::Actor->new;
$aTriangleStripActor->SetMapper($aTriangleStripMapper);
$aTriangleStripActor->AddPosition(8,0,2);
$aTriangleStripActor->GetProperty->BackfaceCullingOn;
$linePoints = Graphics::VTK::Points->new;
$linePoints->SetNumberOfPoints(2);
$linePoints->InsertPoint(0,0,0,0);
$linePoints->InsertPoint(1,1,1,0);
$aLine = Graphics::VTK::Line->new;
$aLine->GetPointIds->SetId(0,0);
$aLine->GetPointIds->SetId(1,1);
$bLine = $aLine->MakeObject;
$aLineGrid = Graphics::VTK::UnstructuredGrid->new;
$aLineGrid->Allocate(1,1);
$aLineGrid->InsertNextCell($aLine->GetCellType,$aLine->GetPointIds);
$aLineGrid->SetPoints($linePoints);
$aLineMapper = Graphics::VTK::DataSetMapper->new;
$aLineMapper->SetInput($aLineGrid);
$aLineActor = Graphics::VTK::Actor->new;
$aLineActor->SetMapper($aLineMapper);
$aLineActor->AddPosition(0,0,4);
$aLineActor->GetProperty->BackfaceCullingOn;
$polyLinePoints = Graphics::VTK::Points->new;
$polyLinePoints->SetNumberOfPoints(3);
$polyLinePoints->InsertPoint(0,0,0,0);
$polyLinePoints->InsertPoint(1,1,1,0);
$polyLinePoints->InsertPoint(2,1,0,0);
$aPolyLine = Graphics::VTK::PolyLine->new;
$aPolyLine->GetPointIds->SetNumberOfIds(3);
$aPolyLine->GetPointIds->SetId(0,0);
$aPolyLine->GetPointIds->SetId(1,1);
$aPolyLine->GetPointIds->SetId(2,2);
$bPolyLine = $aPolyLine->MakeObject;
$aPolyLineGrid = Graphics::VTK::UnstructuredGrid->new;
$aPolyLineGrid->Allocate(1,1);
$aPolyLineGrid->InsertNextCell($aPolyLine->GetCellType,$aPolyLine->GetPointIds);
$aPolyLineGrid->SetPoints($polyLinePoints);
$aPolyLineMapper = Graphics::VTK::DataSetMapper->new;
$aPolyLineMapper->SetInput($aPolyLineGrid);
$aPolyLineActor = Graphics::VTK::Actor->new;
$aPolyLineActor->SetMapper($aPolyLineMapper);
$aPolyLineActor->AddPosition(2,0,4);
$aPolyLineActor->GetProperty->BackfaceCullingOn;
$vertexPoints = Graphics::VTK::Points->new;
$vertexPoints->SetNumberOfPoints(1);
$vertexPoints->InsertPoint(0,0,0,0);
$aVertex = Graphics::VTK::Vertex->new;
$aVertex->GetPointIds->SetId(0,0);
$bVertex = $aVertex->MakeObject;
$aVertexGrid = Graphics::VTK::UnstructuredGrid->new;
$aVertexGrid->Allocate(1,1);
$aVertexGrid->InsertNextCell($aVertex->GetCellType,$aVertex->GetPointIds);
$aVertexGrid->SetPoints($vertexPoints);
$aVertexMapper = Graphics::VTK::DataSetMapper->new;
$aVertexMapper->SetInput($aVertexGrid);
$aVertexActor = Graphics::VTK::Actor->new;
$aVertexActor->SetMapper($aVertexMapper);
$aVertexActor->AddPosition(0,0,6);
$aVertexActor->GetProperty->BackfaceCullingOn;
$polyVertexPoints = Graphics::VTK::Points->new;
$polyVertexPoints->SetNumberOfPoints(3);
$polyVertexPoints->InsertPoint(0,0,0,0);
$polyVertexPoints->InsertPoint(1,1,0,0);
$polyVertexPoints->InsertPoint(2,1,1,0);
$aPolyVertex = Graphics::VTK::PolyVertex->new;
$aPolyVertex->GetPointIds->SetNumberOfIds(3);
$aPolyVertex->GetPointIds->SetId(0,0);
$aPolyVertex->GetPointIds->SetId(1,1);
$aPolyVertex->GetPointIds->SetId(2,2);
$bPolyVertex = $aPolyVertex->MakeObject;
$aPolyVertexGrid = Graphics::VTK::UnstructuredGrid->new;
$aPolyVertexGrid->Allocate(1,1);
$aPolyVertexGrid->InsertNextCell($aPolyVertex->GetCellType,$aPolyVertex->GetPointIds);
$aPolyVertexGrid->SetPoints($polyVertexPoints);
$aPolyVertexMapper = Graphics::VTK::DataSetMapper->new;
$aPolyVertexMapper->SetInput($aPolyVertexGrid);
$aPolyVertexActor = Graphics::VTK::Actor->new;
$aPolyVertexActor->SetMapper($aPolyVertexMapper);
$aPolyVertexActor->AddPosition(2,0,6);
$aPolyVertexActor->GetProperty->BackfaceCullingOn;
if (Graphics::VTK::RIBProperty->can('new') ne "")
 {
  $aProperty = Graphics::VTK::RIBProperty->new;
  $aProperty->SetVariable('Km','float');
  $aProperty->SetSurfaceShader('LGVeinedmarble');
  $aProperty->SetVariable('veinfreq','float');
  $aProperty->AddVariable('warpfreq','float');
  $aProperty->AddVariable('veincolor','color');
  $aProperty->AddParameter('veinfreq',2);
  $aProperty->AddParameter('veincolor',$ivory);
  $bProperty = Graphics::VTK::RIBProperty->new;
  $bProperty->SetVariable('Km','float');
  $bProperty->SetParameter('Km',1.0);
  $bProperty->SetDisplacementShader('dented');
  $bProperty->SetSurfaceShader('plastic');
 }
else
 {
  $aProperty = Graphics::VTK::Property->new;
  $bProperty = Graphics::VTK::Property->new;
 }
$aTriangleActor->SetProperty($aProperty);
$aTriangleStripActor->SetProperty($bProperty);
$ren1->SetBackground('.1','.2','.4');
$ren1->AddActor('aVoxelActor');
$aVoxelActor->GetProperty->SetDiffuseColor(1,0,0);
$ren1->AddActor('aHexahedronActor');
$aHexahedronActor->GetProperty->SetDiffuseColor(1,1,0);
$ren1->AddActor('aTetraActor');
$aTetraActor->GetProperty->SetDiffuseColor(0,1,0);
$ren1->AddActor('aWedgeActor');
$aWedgeActor->GetProperty->SetDiffuseColor(0,1,1);
$ren1->AddActor('aPyramidActor');
$aPyramidActor->GetProperty->SetDiffuseColor(1,0,1);
$ren1->AddActor('aPixelActor');
$aPixelActor->GetProperty->SetDiffuseColor(0,1,1);
$ren1->AddActor('aQuadActor');
$aQuadActor->GetProperty->SetDiffuseColor(1,0,1);
$ren1->AddActor('aTriangleActor');
$aTriangleActor->GetProperty->SetDiffuseColor('.3',1,'.5');
$ren1->AddActor('aPolygonActor');
$aPolygonActor->GetProperty->SetDiffuseColor(1,'.4','.5');
$ren1->AddActor('aTriangleStripActor');
$aTriangleStripActor->GetProperty->SetDiffuseColor('.3','.7',1);
$ren1->AddActor('aLineActor');
$aLineActor->GetProperty->SetDiffuseColor('.2',1,1);
$ren1->AddActor('aPolyLineActor');
$aPolyLineActor->GetProperty->SetDiffuseColor(1,1,1);
$ren1->AddActor('aVertexActor');
$aVertexActor->GetProperty->SetDiffuseColor(1,1,1);
$ren1->AddActor('aPolyVertexActor');
$aPolyVertexActor->GetProperty->SetDiffuseColor(1,1,1);
if (Graphics::VTK::RIBLight->can('new') ne "")
 {
  $aLight = Graphics::VTK::RIBLight->new;
  $aLight->ShadowsOn;
  $aLight->PositionalOn;
  $aLight->SetConeAngle(5);
 }
else
 {
  $aLight = Graphics::VTK::Light->new;
  $aLight->PositionalOn;
 }
$ren1->AddLight($aLight);
$ren1->GetActiveCamera->Azimuth(30);
$ren1->GetActiveCamera->Elevation(20);
$ren1->GetActiveCamera->Dolly(1.25);
$ren1->ResetCameraClippingRange;
$aLight->SetFocalPoint($ren1->GetActiveCamera->GetFocalPoint);
$aLight->SetPosition($ren1->GetActiveCamera->GetPosition);
$renWin->Render;
$vrml = Graphics::VTK::VRMLExporter->new;
$vrml->SetInput($renWin);
$vrml->SetStartWrite('vrml SetFileName cells.wrl');
$vrml->SetEndWrite('vrml SetFileName /a/acells.wrl');
$vrml->SetSpeed(5.5);
$vrml->Write;
if (Graphics::VTK::RIBExporter->can('new') ne "")
 {
  $atext = Graphics::VTK::Texture->new;
  $pnmReader = Graphics::VTK::PNMReader->new;
  $pnmReader->SetFileName("$VTK_DATA/masonry.ppm");
  $atext->SetInput($pnmReader->GetOutput);
  $atext->InterpolateOff;
  $aTriangleActor->SetTexture($atext);
  $rib = Graphics::VTK::RIBExporter->new;
  $rib->SetInput($renWin);
  $rib->SetFilePrefix('cells');
  $rib->SetTexturePrefix('cells');
  $rib->Write;
 }
$iv = Graphics::VTK::IVExporter->new;
$iv->SetInput($renWin);
$iv->SetFileName('cells.iv');
$iv->Write;
$obj = Graphics::VTK::OBJExporter->new;
$obj->SetInput($renWin);
$obj->SetFilePrefix('cells');
$obj->Write;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$MW->withdraw;
#renWin SetFileName "cells.tcl.ppm"
#renWin SaveImageAsPPM
# the UnRegister calls are because make object is the same as New,
# and causes memory leaks. (Tcl does not treat MakeObject the same as New).
#
sub DeleteCopies
{
 # Global Variables Declared for this function: bVoxel, bHexahedron, bTetra, bPixel, bQuad, bTriangle, bPolygon
 # Global Variables Declared for this function: bTriangleStrip, bLine, bPolyLine, bVertex, bPolyVertex
 # Global Variables Declared for this function: bWedge, bPyramid














}
DeleteCopies();
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
