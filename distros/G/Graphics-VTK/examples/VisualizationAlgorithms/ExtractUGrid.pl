#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example shows how to extract portions of an unstructured grid
# using vtkExtractUnstructuredGrid. vtkConnectivityFilter is also used
# to extract connected components.

# The data found here represents a blow molding process. Blow molding
# requires a mold and parison (hot, viscous plastic) which is shaped
# by the mold into the final form. The data file contains several steps
# in time for the analysis.


$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};

# Create a reader to read the unstructured grid data. We use a 
# vtkDataSetReader which means the type of the output is unknown until
# the data file is read. SO we follow the reader with a vtkCastToConcrete
# and cast the output to vtkUnstructuredGrid.
$reader = Graphics::VTK::DataSetReader->new;
$reader->SetFileName("$VTK_DATA_ROOT/Data/blow.vtk");
$reader->SetScalarsName("thickness9");
$reader->SetVectorsName("displacement9");
$castToUnstructuredGrid = Graphics::VTK::CastToConcrete->new;
$castToUnstructuredGrid->SetInput($reader->GetOutput);
$warp = Graphics::VTK::WarpVector->new;
$warp->SetInput($castToUnstructuredGrid->GetUnstructuredGridOutput);

# The connectivity filter extracts the first two regions. These are
# know to represent the mold.
$connect = Graphics::VTK::ConnectivityFilter->new;
$connect->SetInput($warp->GetOutput);
$connect->SetExtractionModeToSpecifiedRegions;
$connect->AddSpecifiedRegion(0);
$connect->AddSpecifiedRegion(1);
$moldMapper = Graphics::VTK::DataSetMapper->new;
$moldMapper->SetInput($reader->GetOutput);
$moldMapper->ScalarVisibilityOff;
$moldActor = Graphics::VTK::Actor->new;
$moldActor->SetMapper($moldMapper);
$moldActor->GetProperty->SetColor('.2','.2','.2');
$moldActor->GetProperty->SetRepresentationToWireframe;

# Another connectivity filter is used to extract the parison.
$connect2 = Graphics::VTK::ConnectivityFilter->new;
$connect2->SetInput($warp->GetOutput);
$connect2->SetExtractionModeToSpecifiedRegions;
$connect2->AddSpecifiedRegion(2);
# We use vtkExtractUnstructuredGrid because we are interested in
# looking at just a few cells. We use cell clipping via cell id to
# extract the portion of the grid we are interested in.
$extractGrid = Graphics::VTK::ExtractUnstructuredGrid->new;
$extractGrid->SetInput($connect2->GetOutput);
$extractGrid->CellClippingOn;
$extractGrid->SetCellMinimum(0);
$extractGrid->SetCellMaximum(23);
$parison = Graphics::VTK::GeometryFilter->new;
$parison->SetInput($extractGrid->GetOutput);
$normals2 = Graphics::VTK::PolyDataNormals->new;
$normals2->SetInput($parison->GetOutput);
$normals2->SetFeatureAngle(60);
$lut = Graphics::VTK::LookupTable->new;
$lut->SetHueRange(0.0,0.66667);
$parisonMapper = Graphics::VTK::PolyDataMapper->new;
$parisonMapper->SetInput($normals2->GetOutput);
$parisonMapper->SetLookupTable($lut);
$parisonMapper->SetScalarRange(0.12,1.0);
$parisonActor = Graphics::VTK::Actor->new;
$parisonActor->SetMapper($parisonMapper);

# graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the renderer, set the background and size

$ren1->AddActor($parisonActor);
$ren1->AddActor($moldActor);
$ren1->SetBackground(1,1,1);
$ren1->GetActiveCamera->Azimuth(60);
$ren1->GetActiveCamera->Roll(-90);
$ren1->GetActiveCamera->Dolly(2);
$ren1->ResetCameraClippingRange;
$renWin->SetSize(500,375);
$iren->Initialize;

# prevent the tk window from showing up then start the event loop
$MW->withdraw;

Tk->MainLoop;
