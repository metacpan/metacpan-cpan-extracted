#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl version to demonstrate line smoothing
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create a semi-cylinder
$line = Graphics::VTK::LineSource->new;
$line->SetPoint1(0,0,1);
$line->SetPoint2(50,0,1);
$line->SetResolution(49);
$bump = Graphics::VTK::BrownianPoints->new;
$bump->SetInput($line->GetOutput);
$warp = Graphics::VTK::WarpVector->new;
$warp->SetInput($bump->GetPolyDataOutput);
$warp->SetScaleFactor('.1');
$iterations = "0 10 20 30 40 50";
foreach $iteration ($iterations)
 {
  $smooth{$iteration} = Graphics::VTK::SmoothPolyDataFilter->new;
  $smooth{$iteration}->SetInput($warp->GetOutput);
  $smooth{$iteration}->SetNumberOfIterations($iteration);
  $smooth{$iteration}->BoundarySmoothingOn;
  $smooth{$iteration}->SetFeatureAngle(120);
  $smooth{$iteration}->SetEdgeAngle(90);
  $smooth{$iteration}->SetRelaxationFactor('.025');
  $smooth{$iteration}->GenerateErrorScalarsOn;
  $lineMapper{$iteration} = Graphics::VTK::PolyDataMapper->new;
  $lineMapper{$iteration}->SetInput($smooth{$iteration}->GetOutput);
  $lineMapper{$iteration}->SetScalarRange(0,'.04');
  $lineActor{$iteration} = Graphics::VTK::Actor->new;
  $lineActor{$iteration}->SetMapper($lineMapper{$iteration});
  $lineActor{$iteration}->GetProperty->SetColor(@Graphics::VTK::Colors::beige);
  $ren1->AddActor($lineActor{$iteration});
  $lineActor{$iteration}->AddPosition(0,$iteration,0);
 }
# Add the actors to the renderer, set the background and size
$ren1->SetBackground(1,1,1);
$renWin->SetSize(350,350);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$renWin->SetFileName("smoothLines.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
