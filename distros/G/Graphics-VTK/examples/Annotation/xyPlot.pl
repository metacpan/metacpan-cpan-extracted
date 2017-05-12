#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates the use of vtkXYPlotActor to display three
# probe lines using three different techniques.  In this example, we are
# loading data using the vtkPLOT3DReader.  We are using the vtkProbeFilter
# to extract the underlying point data along three probe lines.


# First we include the VTK Tcl packages which will make available
# all of the vtk commands to Tcl.

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# Create a PLOT3D reader and load the data.

$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA_ROOT/Data/combxyz.bin");
$pl3d->SetQFileName("$VTK_DATA_ROOT/Data/combq.bin");
$pl3d->SetScalarFunctionNumber(100);
$pl3d->SetVectorFunctionNumber(202);
$pl3d->Update;

# Create three the line source to use for the probe lines.
$line = Graphics::VTK::LineSource->new;
$line->SetResolution(30);

# Move the line into place and create the probe filter.  For vtkProbeFilter,
# the probe line is the input, and the underlying data set is the source.
$transL1 = Graphics::VTK::Transform->new;
$transL1->Translate(3.7,0.0,28.37);
$transL1->Scale(5,5,5);
$transL1->RotateY(90);
$tf = Graphics::VTK::TransformPolyDataFilter->new;
$tf->SetInput($line->GetOutput);
$tf->SetTransform($transL1);
$probe = Graphics::VTK::ProbeFilter->new;
$probe->SetInput($tf->GetOutput);
$probe->SetSource($pl3d->GetOutput);

# Move the line again and create another probe filter.
$transL2 = Graphics::VTK::Transform->new;
$transL2->Translate(9.2,0.0,31.20);
$transL2->Scale(5,5,5);
$transL2->RotateY(90);
$tf2 = Graphics::VTK::TransformPolyDataFilter->new;
$tf2->SetInput($line->GetOutput);
$tf2->SetTransform($transL2);
$probe2 = Graphics::VTK::ProbeFilter->new;
$probe2->SetInput($tf2->GetOutput);
$probe2->SetSource($pl3d->GetOutput);

# Move the line again and create a third probe filter.
$transL3 = Graphics::VTK::Transform->new;
$transL3->Translate(13.27,0.0,33.40);
$transL3->Scale(4.5,4.5,4.5);
$transL3->RotateY(90);
$tf3 = Graphics::VTK::TransformPolyDataFilter->new;
$tf3->SetInput($line->GetOutput);
$tf3->SetTransform($transL3);
$probe3 = Graphics::VTK::ProbeFilter->new;
$probe3->SetInput($tf3->GetOutput);
$probe3->SetSource($pl3d->GetOutput);

# Create a vtkAppendPolyData to merge the output of the three probe filters
# into one data set.
$appendF = Graphics::VTK::AppendPolyData->new;
$appendF->AddInput($probe->GetPolyDataOutput);
$appendF->AddInput($probe2->GetPolyDataOutput);
$appendF->AddInput($probe3->GetPolyDataOutput);

# Create a tube filter to represent the lines as tubes.  Set up the associated
# mapper and actor.
$tuber = Graphics::VTK::TubeFilter->new;
$tuber->SetInput($appendF->GetOutput);
$tuber->SetRadius(0.1);
$lineMapper = Graphics::VTK::PolyDataMapper->new;
$lineMapper->SetInput($tuber->GetOutput);
$lineActor = Graphics::VTK::Actor->new;
$lineActor->SetMapper($lineMapper);

# Create an xy-plot using the output of the 3 probe filters as input.
# The x-values we are plotting are arc length.
$xyplot = Graphics::VTK::XYPlotActor->new;
$xyplot->AddInput($probe->GetOutput);
$xyplot->AddInput($probe2->GetOutput);
$xyplot->AddInput($probe3->GetOutput);
$xyplot->GetPositionCoordinate->SetValue(0.0,0.67,0);
$xyplot->GetPosition2Coordinate->SetValue(1.0,0.33,0);
#relative to Position
$xyplot->SetXValuesToArcLength;
$xyplot->SetNumberOfXLabels(6);
$xyplot->SetTitle("Pressure vs. Arc Length (Zoomed View)");
$xyplot->SetXTitle("");
$xyplot->SetYTitle("P");
$xyplot->SetXRange('.1','.35');
$xyplot->SetYRange('.2','.4');
$xyplot->GetProperty->SetColor(0,0,0);
$xyplot->GetProperty->SetLineWidth(2);

# Create an xy-plot using the output of the 3 probe filters as input.
# The x-values we are plotting are normalized arc length.
$xyplot2 = Graphics::VTK::XYPlotActor->new;
$xyplot2->AddInput($probe->GetOutput);
$xyplot2->AddInput($probe2->GetOutput);
$xyplot2->AddInput($probe3->GetOutput);
$xyplot2->GetPositionCoordinate->SetValue(0.00,0.33,0);
$xyplot2->GetPosition2Coordinate->SetValue(1.0,0.33,0);
#relative to Position
$xyplot2->SetXValuesToNormalizedArcLength;
$xyplot2->SetNumberOfXLabels(6);
$xyplot2->SetTitle("Pressure vs. Normalized Arc Length");
$xyplot2->SetXTitle("");
$xyplot2->SetYTitle("P");
$xyplot2->PlotPointsOn;
$xyplot2->PlotLinesOff;
$xyplot2->GetProperty->SetColor(1,0,0);
$xyplot2->GetProperty->SetPointSize(2);

# Create an xy-plot using the output of the 3 probe filters as input.
# The x-values we are plotting are the underlying point data values.
$xyplot3 = Graphics::VTK::XYPlotActor->new;
$xyplot3->AddInput($probe->GetOutput);
$xyplot3->AddInput($probe2->GetOutput);
$xyplot3->AddInput($probe3->GetOutput);
$xyplot3->GetPositionCoordinate->SetValue(0.0,0.0,0);
$xyplot3->GetPosition2Coordinate->SetValue(1.0,0.33,0);
#relative to Position
$xyplot3->SetXValuesToIndex;
$xyplot3->SetNumberOfXLabels(6);
$xyplot3->SetTitle("Pressure vs. Point Id");
$xyplot3->SetXTitle("Probe Length");
$xyplot3->SetYTitle("P");
$xyplot3->PlotPointsOn;
$xyplot3->GetProperty->SetColor(0,0,1);
$xyplot3->GetProperty->SetPointSize(3);

# Draw an outline of the PLOT3D data set.
$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(0,0,0);

# Create the Renderers, RenderWindow, and RenderWindowInteractor.

$ren1 = Graphics::VTK::Renderer->new;
$ren2 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$renWin->AddRenderer($ren2);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Set the background, viewport (necessary because we want to have the
# renderers draw to different parts of the render window) of the first
# renderer.  Add the outline and line actors to the renderer.
$ren1->SetBackground(0.6784,0.8471,0.9020);
$ren1->SetViewport(0,0,'.5',1);
$ren1->AddActor($outlineActor);
$ren1->AddActor($lineActor);

# Set the background and viewport of the second renderer.  Add the xy-plot
# actors to the renderer.  Set the size of the render window.
$ren2->SetBackground(1,1,1);
$ren2->SetViewport(0.5,0.0,1.0,1.0);
$ren2->AddActor2D($xyplot);
$ren2->AddActor2D($xyplot2);
$ren2->AddActor2D($xyplot3);
$renWin->SetSize(500,250);

# Set up the camera parameters.
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(3.95297,100);
$cam1->SetFocalPoint(8.88908,0.595038,29.3342);
$cam1->SetPosition(-12.3332,31.7479,41.2387);
$cam1->SetViewUp(0.060772,-0.319905,0.945498);
$iren->Initialize;

# Set the user method (bound to key 'u')

$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);

# Withdraw the default tk window.
$MW->withdraw;

Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
