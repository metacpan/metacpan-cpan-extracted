#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

## cut a volume with cell data
# get the interactor ui
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInt;
$volume = Graphics::VTK::StructuredPoints->new;
$volume->SetDimensions(5,10,15);
$numScalars = 4 * 9 * 14;
$math = Graphics::VTK::Math->new;
$cellScalars = Graphics::VTK::Scalars->new;
$cellScalars->SetNumberOfScalars($numScalars);
for ($i = 0; $i < $numScalars; $i += 1)
 {
  $cellScalars->SetScalar($i,$math->Random(0,1));
 }
$volume->GetCellData->SetScalars($cellScalars);
# create a sphere source and actor
$plane = Graphics::VTK::Plane->new;
$plane->SetOrigin($volume->GetCenter);
$plane->SetNormal(0,1,1);
$planeCut = Graphics::VTK::Cutter->new;
$planeCut->SetInput($volume);
$planeCut->SetCutFunction($plane);
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($planeCut->GetOutput);
$mapper->GlobalImmediateModeRenderingOn;
$cutActor = Graphics::VTK::LODActor->new;
$cutActor->SetMapper($mapper);
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($volume);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($cutActor);
$ren1->AddActor($outlineActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(300,300);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$cam1 = $ren1->GetActiveCamera;
$cam1->SetClippingRange(3.83384,191.692);
$cam1->SetFocalPoint(1.67401,3.99838,7.71124);
$cam1->SetPosition(26.1644,21.623,31.3635);
$cam1->ComputeViewPlaneNormal;
$cam1->SetViewUp(-0.321615,0.887994,-0.328681);
$cam1->Dolly(1.4);
$iren->Initialize;
$renWin->SetFileName("cutCells.tcl.ppm");
#renWin SaveImageAsPPM
#
sub TkCheckAbort
{
 my $foo;
 $foo = $renWin->GetEventPending;
 $renWin->SetAbortRender(1) if ($foo != 0);
}
$renWin->SetAbortCheckMethod(
 sub
  {
   TkCheckAbort();
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
