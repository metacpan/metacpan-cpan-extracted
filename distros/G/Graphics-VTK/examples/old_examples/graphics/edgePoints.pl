#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Generate marching cubes head model (full resolution)
# get the interactor ui and colors
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# create pipeline
# reader reads slices
$v16 = Graphics::VTK::Volume16Reader->new;
$v16->SetDataDimensions(256,256);
$v16->SetDataByteOrderToLittleEndian;
$v16->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$v16->SetDataSpacing(0.8,0.8,1.5);
$v16->SetImageRange(30,50);
$v16->SetDataMask(0x7fff);
# create points on edges
$edgePoints = Graphics::VTK::EdgePoints->new;
$edgePoints->SetInput($v16->GetOutput);
$edgePoints->SetValue(1150);
$mapper = Graphics::VTK::DataSetMapper->new;
$mapper->SetInput($edgePoints->GetOutput);
$mapper->ImmediateModeRenderingOn;
$head = Graphics::VTK::Actor->new;
$head->SetMapper($mapper);
$head->GetProperty->SetColor(@Graphics::VTK::Colors::raw_sienna);
# Create the RenderWindow, Renderer and Interactor
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($head);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$ren1->SetBackground($slate_grey);
$ren1->GetActiveCamera->Zoom(1.5);
$ren1->GetActiveCamera->Elevation(90);
$ren1->ResetCameraClippingRange;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->Render;
#renWin SetFileName "edgePoints.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
