#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates the conversion of point data to cell data.
# The conversion is necessary because we want to threshold data based
# on cell scalar values.

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# Read some data with point data attributes. The data is from a plastic
# blow molding process (e.g., to make plastic bottles) and consists of two
# logical components: a mold and a parison. The parison is the
# hot plastic that is being molded, and the mold is clamped around the
# parison to form its shape.
$reader = Graphics::VTK::UnstructuredGridReader->new;
$reader->SetFileName("$VTK_DATA_ROOT/Data/blow.vtk");
$reader->SetScalarsName("thickness9");
$reader->SetVectorsName("displacement9");

# Convert the point data to cell data. The point data is passed through the
# filter so it can be warped. The vtkThresholdFilter then thresholds based
# on cell scalar values and extracts a portion of the parison whose cell
# scalar values lie between 0.25 and 0.75.
$p2c = Graphics::VTK::PointDataToCellData->new;
$p2c->SetInput($reader->GetOutput);
$p2c->PassPointDataOn;
$warp = Graphics::VTK::WarpVector->new;
$warp->SetInput($p2c->GetUnstructuredGridOutput);
$thresh = Graphics::VTK::Threshold->new;
$thresh->SetInput($warp->GetOutput);
$thresh->ThresholdBetween(0.25,0.75);
$thresh->SetAttributeModeToUseCellData;

# This is used to extract the mold from the parison. 
$connect = Graphics::VTK::ConnectivityFilter->new;
$connect->SetInput($thresh->GetOutput);
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

# The threshold filter has been used to extract the parison.
$connect2 = Graphics::VTK::ConnectivityFilter->new;
$connect2->SetInput($thresh->GetOutput);
$parison = Graphics::VTK::GeometryFilter->new;
$parison->SetInput($connect2->GetOutput);
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

# We generate some contour lines on the parison.
$cf = Graphics::VTK::ContourFilter->new;
$cf->SetInput($connect2->GetOutput);
$cf->SetValue(0,'.5');
$contourMapper = Graphics::VTK::PolyDataMapper->new;
$contourMapper->SetInput($cf->GetOutput);
$contours = Graphics::VTK::Actor->new;
$contours->SetMapper($contourMapper);

# Create graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the renderer, set the background and size
$ren1->AddActor($moldActor);
$ren1->AddActor($parisonActor);
$ren1->AddActor($contours);

$ren1->GetActiveCamera->Azimuth(60);
$ren1->GetActiveCamera->Roll(-90);
$ren1->GetActiveCamera->Dolly(2);
$ren1->ResetCameraClippingRange;

$ren1->SetBackground(1,1,1);
$renWin->SetSize(750,400);

$iren->Initialize;
$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);

# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
