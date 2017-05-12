#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example demonstrates the use of 2D text.


# First we include the VTK Tcl packages which will make available
# all of the vtk commands to Tcl

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# Create a sphere source, mapper, and actor
$sphere = Graphics::VTK::SphereSource->new;

$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($sphere->GetOutput);
$sphereMapper->GlobalImmediateModeRenderingOn;
$sphereActor = Graphics::VTK::LODActor->new;
$sphereActor->SetMapper($sphereMapper);

# Create a text mapper.  Set the text, font, justification, and text
# properties (bold, italics, etc.).
$textMapper = Graphics::VTK::TextMapper->new;
$textMapper->SetInput("This is a sphere");
$textMapper->SetFontSize(18);
$textMapper->SetFontFamilyToArial;
$textMapper->SetJustificationToCentered;
$textMapper->BoldOn;
$textMapper->ItalicOn;
$textMapper->ShadowOn;

# Create a scaled text actor. Set the position and color of the text.
$textActor = Graphics::VTK::ScaledTextActor->new;
$textActor->SetMapper($textMapper);
$textActor->SetDisplayPosition(90,50);
$textActor->GetProperty->SetColor(0,0,1);

# Create the Renderer, RenderWindow, RenderWindowInteractor

$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the renderer; set the background and size; zoom in
# and render.

$ren1->AddActor2D($textActor);
$ren1->AddActor($sphereActor);

$ren1->SetBackground(1,1,1);
$renWin->SetSize(250,125);
$ren1->GetActiveCamera->Zoom(1.5);
$renWin->Render;

# Set the user method (bound to key 'u')
$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);

# Withdraw the tk window
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
