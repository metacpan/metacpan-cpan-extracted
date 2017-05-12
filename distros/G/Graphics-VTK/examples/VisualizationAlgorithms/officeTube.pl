#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates the use of a single streamline and the tube
# filter to create a streamtube.


# First we include the VTK Tcl packages which will make available
# all of the vtk commands from Tcl. The vtkinteraction package defines
# a simple Tcl/Tk interactor widget.

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;

# We read a data file the is a CFD analysis of airflow in an office (with
# ventilation and a burning cigarette). We force an update so that we
# can query the output for its length, i.e., the length of the diagonal
# of the bounding box. This is useful for normalizing the data.

$reader = Graphics::VTK::StructuredGridReader->new;
$reader->SetFileName("$VTK_DATA_ROOT/Data/office.binary.vtk");
$reader->Update;
#force a read to occur

$length = $reader->GetOutput->GetLength;

$maxVelocity = $reader->GetOutput->GetPointData->GetVectors->GetMaxNorm;
$maxTime = 35.0 * $length / $maxVelocity;

# Now we will generate a single streamline in the data. We select the
# integration order to use (RungeKutta order 4) and associate it with
# the streamer. The start position is the position in world space where
# we want to begin streamline integration; and we integrate in both
# directions. The step length is the length of the line segments that
# make up the streamline (i.e., related to display). The 
# IntegrationStepLength specifies the integration step length as a 
# fraction of the cell size that the streamline is in.
$integ = Graphics::VTK::RungeKutta4->new;
$streamer = Graphics::VTK::StreamLine->new;
$streamer->SetInput($reader->GetOutput);
$streamer->SetStartPosition(0.1,2.1,0.5);
$streamer->SetMaximumPropagationTime(500);
$streamer->SetStepLength(0.5);
$streamer->SetIntegrationStepLength(0.05);
$streamer->SetIntegrationDirectionToIntegrateBothDirections;
$streamer->SetIntegrator($integ);

# The tube is wrapped around the generated streamline. By varying the radius
# by the inverse of vector magnitude, we are creating a tube whose radius is
# proportional to mass flux (in incompressible flow).
$streamTube = Graphics::VTK::TubeFilter->new;
$streamTube->SetInput($streamer->GetOutput);
$streamTube->SetRadius(0.02);
$streamTube->SetNumberOfSides(12);
$streamTube->SetVaryRadiusToVaryRadiusByVector;
$mapStreamTube = Graphics::VTK::PolyDataMapper->new;
$mapStreamTube->SetInput($streamTube->GetOutput);
$mapStreamTube->SetScalarRange($reader->GetOutput->GetPointData->GetScalars->GetRange);
$streamTubeActor = Graphics::VTK::Actor->new;
$streamTubeActor->SetMapper($mapStreamTube);
$streamTubeActor->GetProperty->BackfaceCullingOn;

# From here on we generate a whole bunch of planes which correspond to
# the geometry in the analysis; tables, bookshelves and so on.
$table1 = Graphics::VTK::StructuredGridGeometryFilter->new;
$table1->SetInput($reader->GetOutput);
$table1->SetExtent(11,15,7,9,8,8);
$mapTable1 = Graphics::VTK::PolyDataMapper->new;
$mapTable1->SetInput($table1->GetOutput);
$mapTable1->ScalarVisibilityOff;
$table1Actor = Graphics::VTK::Actor->new;
$table1Actor->SetMapper($mapTable1);
$table1Actor->GetProperty->SetColor('.59','.427','.392');

$table2 = Graphics::VTK::StructuredGridGeometryFilter->new;
$table2->SetInput($reader->GetOutput);
$table2->SetExtent(11,15,10,12,8,8);
$mapTable2 = Graphics::VTK::PolyDataMapper->new;
$mapTable2->SetInput($table2->GetOutput);
$mapTable2->ScalarVisibilityOff;
$table2Actor = Graphics::VTK::Actor->new;
$table2Actor->SetMapper($mapTable2);
$table2Actor->GetProperty->SetColor('.59','.427','.392');

$FilingCabinet1 = Graphics::VTK::StructuredGridGeometryFilter->new;
$FilingCabinet1->SetInput($reader->GetOutput);
$FilingCabinet1->SetExtent(15,15,7,9,0,8);
$mapFilingCabinet1 = Graphics::VTK::PolyDataMapper->new;
$mapFilingCabinet1->SetInput($FilingCabinet1->GetOutput);
$mapFilingCabinet1->ScalarVisibilityOff;
$FilingCabinet1Actor = Graphics::VTK::Actor->new;
$FilingCabinet1Actor->SetMapper($mapFilingCabinet1);
$FilingCabinet1Actor->GetProperty->SetColor('.8','.8','.6');

$FilingCabinet2 = Graphics::VTK::StructuredGridGeometryFilter->new;
$FilingCabinet2->SetInput($reader->GetOutput);
$FilingCabinet2->SetExtent(15,15,10,12,0,8);
$mapFilingCabinet2 = Graphics::VTK::PolyDataMapper->new;
$mapFilingCabinet2->SetInput($FilingCabinet2->GetOutput);
$mapFilingCabinet2->ScalarVisibilityOff;
$FilingCabinet2Actor = Graphics::VTK::Actor->new;
$FilingCabinet2Actor->SetMapper($mapFilingCabinet2);
$FilingCabinet2Actor->GetProperty->SetColor('.8','.8','.6');

$bookshelf1Top = Graphics::VTK::StructuredGridGeometryFilter->new;
$bookshelf1Top->SetInput($reader->GetOutput);
$bookshelf1Top->SetExtent(13,13,0,4,0,11);
$mapBookshelf1Top = Graphics::VTK::PolyDataMapper->new;
$mapBookshelf1Top->SetInput($bookshelf1Top->GetOutput);
$mapBookshelf1Top->ScalarVisibilityOff;
$bookshelf1TopActor = Graphics::VTK::Actor->new;
$bookshelf1TopActor->SetMapper($mapBookshelf1Top);
$bookshelf1TopActor->GetProperty->SetColor('.8','.8','.6');

$bookshelf1Bottom = Graphics::VTK::StructuredGridGeometryFilter->new;
$bookshelf1Bottom->SetInput($reader->GetOutput);
$bookshelf1Bottom->SetExtent(20,20,0,4,0,11);
$mapBookshelf1Bottom = Graphics::VTK::PolyDataMapper->new;
$mapBookshelf1Bottom->SetInput($bookshelf1Bottom->GetOutput);
$mapBookshelf1Bottom->ScalarVisibilityOff;
$bookshelf1BottomActor = Graphics::VTK::Actor->new;
$bookshelf1BottomActor->SetMapper($mapBookshelf1Bottom);
$bookshelf1BottomActor->GetProperty->SetColor('.8','.8','.6');

$bookshelf1Front = Graphics::VTK::StructuredGridGeometryFilter->new;
$bookshelf1Front->SetInput($reader->GetOutput);
$bookshelf1Front->SetExtent(13,20,0,0,0,11);
$mapBookshelf1Front = Graphics::VTK::PolyDataMapper->new;
$mapBookshelf1Front->SetInput($bookshelf1Front->GetOutput);
$mapBookshelf1Front->ScalarVisibilityOff;
$bookshelf1FrontActor = Graphics::VTK::Actor->new;
$bookshelf1FrontActor->SetMapper($mapBookshelf1Front);
$bookshelf1FrontActor->GetProperty->SetColor('.8','.8','.6');

$bookshelf1Back = Graphics::VTK::StructuredGridGeometryFilter->new;
$bookshelf1Back->SetInput($reader->GetOutput);
$bookshelf1Back->SetExtent(13,20,4,4,0,11);
$mapBookshelf1Back = Graphics::VTK::PolyDataMapper->new;
$mapBookshelf1Back->SetInput($bookshelf1Back->GetOutput);
$mapBookshelf1Back->ScalarVisibilityOff;
$bookshelf1BackActor = Graphics::VTK::Actor->new;
$bookshelf1BackActor->SetMapper($mapBookshelf1Back);
$bookshelf1BackActor->GetProperty->SetColor('.8','.8','.6');

$bookshelf1LHS = Graphics::VTK::StructuredGridGeometryFilter->new;
$bookshelf1LHS->SetInput($reader->GetOutput);
$bookshelf1LHS->SetExtent(13,20,0,4,0,0);
$mapBookshelf1LHS = Graphics::VTK::PolyDataMapper->new;
$mapBookshelf1LHS->SetInput($bookshelf1LHS->GetOutput);
$mapBookshelf1LHS->ScalarVisibilityOff;
$bookshelf1LHSActor = Graphics::VTK::Actor->new;
$bookshelf1LHSActor->SetMapper($mapBookshelf1LHS);
$bookshelf1LHSActor->GetProperty->SetColor('.8','.8','.6');

$bookshelf1RHS = Graphics::VTK::StructuredGridGeometryFilter->new;
$bookshelf1RHS->SetInput($reader->GetOutput);
$bookshelf1RHS->SetExtent(13,20,0,4,11,11);
$mapBookshelf1RHS = Graphics::VTK::PolyDataMapper->new;
$mapBookshelf1RHS->SetInput($bookshelf1RHS->GetOutput);
$mapBookshelf1RHS->ScalarVisibilityOff;
$bookshelf1RHSActor = Graphics::VTK::Actor->new;
$bookshelf1RHSActor->SetMapper($mapBookshelf1RHS);
$bookshelf1RHSActor->GetProperty->SetColor('.8','.8','.6');

$bookshelf2Top = Graphics::VTK::StructuredGridGeometryFilter->new;
$bookshelf2Top->SetInput($reader->GetOutput);
$bookshelf2Top->SetExtent(13,13,15,19,0,11);
$mapBookshelf2Top = Graphics::VTK::PolyDataMapper->new;
$mapBookshelf2Top->SetInput($bookshelf2Top->GetOutput);
$mapBookshelf2Top->ScalarVisibilityOff;
$bookshelf2TopActor = Graphics::VTK::Actor->new;
$bookshelf2TopActor->SetMapper($mapBookshelf2Top);
$bookshelf2TopActor->GetProperty->SetColor('.8','.8','.6');

$bookshelf2Bottom = Graphics::VTK::StructuredGridGeometryFilter->new;
$bookshelf2Bottom->SetInput($reader->GetOutput);
$bookshelf2Bottom->SetExtent(20,20,15,19,0,11);
$mapBookshelf2Bottom = Graphics::VTK::PolyDataMapper->new;
$mapBookshelf2Bottom->SetInput($bookshelf2Bottom->GetOutput);
$mapBookshelf2Bottom->ScalarVisibilityOff;
$bookshelf2BottomActor = Graphics::VTK::Actor->new;
$bookshelf2BottomActor->SetMapper($mapBookshelf2Bottom);
$bookshelf2BottomActor->GetProperty->SetColor('.8','.8','.6');

$bookshelf2Front = Graphics::VTK::StructuredGridGeometryFilter->new;
$bookshelf2Front->SetInput($reader->GetOutput);
$bookshelf2Front->SetExtent(13,20,15,15,0,11);
$mapBookshelf2Front = Graphics::VTK::PolyDataMapper->new;
$mapBookshelf2Front->SetInput($bookshelf2Front->GetOutput);
$mapBookshelf2Front->ScalarVisibilityOff;
$bookshelf2FrontActor = Graphics::VTK::Actor->new;
$bookshelf2FrontActor->SetMapper($mapBookshelf2Front);
$bookshelf2FrontActor->GetProperty->SetColor('.8','.8','.6');

$bookshelf2Back = Graphics::VTK::StructuredGridGeometryFilter->new;
$bookshelf2Back->SetInput($reader->GetOutput);
$bookshelf2Back->SetExtent(13,20,19,19,0,11);
$mapBookshelf2Back = Graphics::VTK::PolyDataMapper->new;
$mapBookshelf2Back->SetInput($bookshelf2Back->GetOutput);
$mapBookshelf2Back->ScalarVisibilityOff;
$bookshelf2BackActor = Graphics::VTK::Actor->new;
$bookshelf2BackActor->SetMapper($mapBookshelf2Back);
$bookshelf2BackActor->GetProperty->SetColor('.8','.8','.6');

$bookshelf2LHS = Graphics::VTK::StructuredGridGeometryFilter->new;
$bookshelf2LHS->SetInput($reader->GetOutput);
$bookshelf2LHS->SetExtent(13,20,15,19,0,0);
$mapBookshelf2LHS = Graphics::VTK::PolyDataMapper->new;
$mapBookshelf2LHS->SetInput($bookshelf2LHS->GetOutput);
$mapBookshelf2LHS->ScalarVisibilityOff;
$bookshelf2LHSActor = Graphics::VTK::Actor->new;
$bookshelf2LHSActor->SetMapper($mapBookshelf2LHS);
$bookshelf2LHSActor->GetProperty->SetColor('.8','.8','.6');

$bookshelf2RHS = Graphics::VTK::StructuredGridGeometryFilter->new;
$bookshelf2RHS->SetInput($reader->GetOutput);
$bookshelf2RHS->SetExtent(13,20,15,19,11,11);
$mapBookshelf2RHS = Graphics::VTK::PolyDataMapper->new;
$mapBookshelf2RHS->SetInput($bookshelf2RHS->GetOutput);
$mapBookshelf2RHS->ScalarVisibilityOff;
$bookshelf2RHSActor = Graphics::VTK::Actor->new;
$bookshelf2RHSActor->SetMapper($mapBookshelf2RHS);
$bookshelf2RHSActor->GetProperty->SetColor('.8','.8','.6');

$window = Graphics::VTK::StructuredGridGeometryFilter->new;
$window->SetInput($reader->GetOutput);
$window->SetExtent(20,20,6,13,10,13);
$mapWindow = Graphics::VTK::PolyDataMapper->new;
$mapWindow->SetInput($window->GetOutput);
$mapWindow->ScalarVisibilityOff;
$windowActor = Graphics::VTK::Actor->new;
$windowActor->SetMapper($mapWindow);
$windowActor->GetProperty->SetColor('.3','.3','.5');

$outlet = Graphics::VTK::StructuredGridGeometryFilter->new;
$outlet->SetInput($reader->GetOutput);
$outlet->SetExtent(0,0,9,10,14,16);
$mapOutlet = Graphics::VTK::PolyDataMapper->new;
$mapOutlet->SetInput($outlet->GetOutput);
$mapOutlet->ScalarVisibilityOff;
$outletActor = Graphics::VTK::Actor->new;
$outletActor->SetMapper($mapOutlet);
$outletActor->GetProperty->SetColor(0,0,0);

$inlet = Graphics::VTK::StructuredGridGeometryFilter->new;
$inlet->SetInput($reader->GetOutput);
$inlet->SetExtent(0,0,9,10,0,6);
$mapInlet = Graphics::VTK::PolyDataMapper->new;
$mapInlet->SetInput($inlet->GetOutput);
$mapInlet->ScalarVisibilityOff;
$inletActor = Graphics::VTK::Actor->new;
$inletActor->SetMapper($mapInlet);
$inletActor->GetProperty->SetColor(0,0,0);

$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($reader->GetOutput);
$mapOutline = Graphics::VTK::PolyDataMapper->new;
$mapOutline->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($mapOutline);
$outlineActor->GetProperty->SetColor(0,0,0);

# Now create the usual graphics stuff.
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

$ren1->AddActor($table1Actor);
$ren1->AddActor($table2Actor);
$ren1->AddActor($FilingCabinet1Actor);
$ren1->AddActor($FilingCabinet2Actor);
$ren1->AddActor($bookshelf1TopActor);
$ren1->AddActor($bookshelf1BottomActor);
$ren1->AddActor($bookshelf1FrontActor);
$ren1->AddActor($bookshelf1BackActor);
$ren1->AddActor($bookshelf1LHSActor);
$ren1->AddActor($bookshelf1RHSActor);
$ren1->AddActor($bookshelf2TopActor);
$ren1->AddActor($bookshelf2BottomActor);
$ren1->AddActor($bookshelf2FrontActor);
$ren1->AddActor($bookshelf2BackActor);
$ren1->AddActor($bookshelf2LHSActor);
$ren1->AddActor($bookshelf2RHSActor);
$ren1->AddActor($windowActor);
$ren1->AddActor($outletActor);
$ren1->AddActor($inletActor);
$ren1->AddActor($outlineActor);
$ren1->AddActor($streamTubeActor);

$ren1->SetBackground(@Graphics::VTK::Colors::slate_grey);

# Here we specify a particular view.
$aCamera = Graphics::VTK::Camera->new;
$aCamera->SetClippingRange(0.726079,36.3039);
$aCamera->SetFocalPoint(2.43584,2.15046,1.11104);
$aCamera->SetPosition(-4.76183,-10.4426,3.17203);
$aCamera->SetViewUp(0.0511273,0.132773,0.989827);
$aCamera->SetViewAngle(18.604);
$aCamera->Zoom(1.2);

$ren1->SetActiveCamera($aCamera);

$renWin->SetSize(500,300);
$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;

# interact with data
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
