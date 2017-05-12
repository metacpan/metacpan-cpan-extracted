#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates the generation of a streamsurface.


# First we include the VTK Tcl packages which will make available
# all of the vtk commands from Tcl. The vtkinteraction package defines
# a simple Tcl/Tk interactor widget.

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;

# create pipeline

$pl3d = Graphics::VTK::PLOT3DReader->new;
$pl3d->SetXYZFileName("$VTK_DATA_ROOT/Data/combxyz.bin");
$pl3d->SetQFileName("$VTK_DATA_ROOT/Data/combq.bin");
$pl3d->SetScalarFunctionNumber(100);
$pl3d->SetVectorFunctionNumber(202);
$pl3d->Update;

# We use a rake to generate a series of streamline starting points
# scattered along a line. Each point will generate a streamline. These
# streamlines are then fed to the vtkRuledSurfaceFilter which stitches
# the lines together to form a surface.
$rake = Graphics::VTK::LineSource->new;
$rake->SetPoint1(15,-5,32);
$rake->SetPoint2(15,5,32);
$rake->SetResolution(21);
$rakeMapper = Graphics::VTK::PolyDataMapper->new;
$rakeMapper->SetInput($rake->GetOutput);
$rakeActor = Graphics::VTK::Actor->new;
$rakeActor->SetMapper($rakeMapper);

$integ = Graphics::VTK::RungeKutta4->new;
$sl = Graphics::VTK::StreamLine->new;
$sl->SetInput($pl3d->GetOutput);
$sl->SetSource($rake->GetOutput);
$sl->SetIntegrator($integ);
$sl->SetMaximumPropagationTime(0.1);
$sl->SetIntegrationStepLength(0.1);
$sl->SetIntegrationDirectionToBackward;
$sl->SetStepLength(0.001);

# Note the SetOnRation method. It turns on every other strip that
# the filter generates (only when multiple lines are input).
$scalarSurface = Graphics::VTK::RuledSurfaceFilter->new;
$scalarSurface->SetInput($sl->GetOutput);
$scalarSurface->SetOffset(0);
$scalarSurface->SetOnRatio(2);
$scalarSurface->PassLinesOn;
$scalarSurface->SetRuledModeToPointWalk;
$scalarSurface->SetDistanceFactor(30);
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($scalarSurface->GetOutput);
$mapper->SetScalarRange($pl3d->GetOutput->GetScalarRange);
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);

$outline = Graphics::VTK::StructuredGridOutlineFilter->new;
$outline->SetInput($pl3d->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(0,0,0);

# Now create the usual graphics stuff.
$ren = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

$ren->AddActor($rakeActor);
$ren->AddActor($actor);
$ren->AddActor($outlineActor);
$ren->SetBackground(1,1,1);

$renWin->SetSize(300,300);

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
