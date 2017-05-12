#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
use KeyFrame; # Keyframe obj in this directory
$MW = Tk::MainWindow->new;

# This example demonstrates keyframe animation. It changes the
# camera's azimuth by interpolating given azimuth values (using splines)

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};

# Get keyframe procs
# See KeyFrame.tcl for details.
use KeyFrame;

# Reduce the number of frames if this example
# is taking too long
$NumberOfFrames = 400;

# Create bottle profile. This is the object to be rendered.
$points = Graphics::VTK::Points->new;
$points->InsertPoint(0,0.01,0.0,0.0);
$points->InsertPoint(1,1.5,0.0,0.0);
$points->InsertPoint(2,1.5,0.0,3.5);
$points->InsertPoint(3,1.25,0.0,3.75);
$points->InsertPoint(4,0.75,0.0,4.00);
$points->InsertPoint(5,0.6,0.0,4.35);
$points->InsertPoint(6,0.7,0.0,4.65);
$points->InsertPoint(7,1.0,0.0,4.75);
$points->InsertPoint(8,1.0,0.0,5.0);
$points->InsertPoint(9,0.01,0.0,5.0);

$lines = Graphics::VTK::CellArray->new;
$lines->InsertNextCell(10);
#number of points
$lines->InsertCellPoint(0);
$lines->InsertCellPoint(1);
$lines->InsertCellPoint(2);
$lines->InsertCellPoint(3);
$lines->InsertCellPoint(4);
$lines->InsertCellPoint(5);
$lines->InsertCellPoint(6);
$lines->InsertCellPoint(7);
$lines->InsertCellPoint(8);
$lines->InsertCellPoint(9);

$profile = Graphics::VTK::PolyData->new;
$profile->SetPoints($points);
$profile->SetLines($lines);

# Extrude profile to make bottle
$extrude = Graphics::VTK::RotationalExtrusionFilter->new;
$extrude->SetInput($profile);
$extrude->SetResolution(60);

$map = Graphics::VTK::PolyDataMapper->new;
$map->SetInput($extrude->GetOutput);

$bottle = Graphics::VTK::Actor->new;
$bottle->SetMapper($map);
$bottle->GetProperty->SetColor(0.3800,0.7000,0.1600);

# Create the RenderWindow, Renderer
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);

# Add the actor to the renderer, set the background and size#
$ren1->AddActor($bottle);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
# First render, forces the renderer to create a camera with a
# good initial position
$renWin->Render;

# prevent the tk window from showing up then start the event loop
$MW->withdraw;

# Initialize keyframe recording by passing the camera object
# and the method used to change the position
$camera = $ren1->GetActiveCamera;
$Azimuth = Graphics::VTK::KeyFrame->new($camera, 'SetPosition',$renWin);

# Define the key frames.
# This is done by changing the position of the camera with
# $camera Azimuth and recording it with KeyAdd
# This is far simpler than calculating the new position by hand.
$Azimuth->Add($camera->GetPosition);
$camera->Azimuth(1);
$Azimuth->Add($camera->GetPosition);
$camera->Azimuth(2);
$Azimuth->Add($camera->GetPosition);
for ($i = 0; $i <= 36; $i += 1)
 {
  $camera->Azimuth(10);
  $Azimuth->Add($camera->GetPosition);
 }
$camera->Azimuth(2);
$Azimuth->Add($camera->GetPosition);
$camera->Azimuth(1);
$Azimuth->Add($camera->GetPosition);

$camera->Azimuth(0);
$Azimuth->Add($camera->GetPosition);

$camera->Azimuth(-1);
$Azimuth->Add($camera->GetPosition);
$camera->Azimuth(-2);
$Azimuth->Add($camera->GetPosition);
for ($i = 0; $i <= 36; $i += 1)
 {
  $camera->Azimuth(-10);
  $Azimuth->Add($camera->GetPosition);
 }
$camera->Azimuth(-2);
$Azimuth->Add($camera->GetPosition);
$camera->Azimuth(-1);
$Azimuth->Add($camera->GetPosition);

# Run the animation - NumberOfFrames frames - 
# using interpolation
$Azimuth->Run($NumberOfFrames);

# Clean-up and exit



