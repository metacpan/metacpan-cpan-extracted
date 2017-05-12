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
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# prompt for input filename
$puts->_nonewline("Input marching cubes filename>> ");
$gets->stdin('fileName');
$puts->_nonewline("Input marching cubes limits filename>> ");
$gets->stdin('limitsName');
# read from file
$reader = Graphics::VTK::MCubesReader->new;
$reader->SetFileName($fileName);
$reader->SetLimitsFileName($limitsName);
$reader->DebugOn;
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($reader->GetOutput);
$head = Graphics::VTK::Actor->new;
$head->SetMapper($mapper);
$head->GetProperty->SetColor(@Graphics::VTK::Colors::raw_sienna);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($head);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$ren1->SetBackground($slate_grey);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
$iren->Initialize;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
