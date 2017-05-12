#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# create pipeline
$v16 = Graphics::VTK::Volume16Reader->new;
$v16->SetDataDimensions(128,128);
$v16->GetOutput->SetOrigin(0.0,0.0,0.0);
$v16->SetDataByteOrderToLittleEndian;
$v16->SetFilePrefix("$VTK_DATA/headsq/half");
$v16->SetImageRange(1,93);
$v16->SetDataSpacing(1.6,1.6,1.5);
$v16->Update;
$myLocator = Graphics::VTK::MergePoints->new;
$isoXY = Graphics::VTK::MarchingSquares->new;
$isoXY->SetInput($v16->GetOutput);
$isoXY->GenerateValues(2,600,1200);
$isoXY->SetImageRange(0,64,64,127,45,45);
$isoXY->SetLocator($myLocator);
$isoXYMapper = Graphics::VTK::PolyDataMapper->new;
$isoXYMapper->SetInput($isoXY->GetOutput);
$isoXYMapper->SetScalarRange(600,1200);
$isoXYActor = Graphics::VTK::Actor->new;
$isoXYActor->SetMapper($isoXYMapper);
$isoYZ = Graphics::VTK::MarchingSquares->new;
$isoYZ->SetInput($v16->GetOutput);
$isoYZ->GenerateValues(2,600,1200);
$isoYZ->SetImageRange(64,64,64,127,46,92);
$isoYZMapper = Graphics::VTK::PolyDataMapper->new;
$isoYZMapper->SetInput($isoYZ->GetOutput);
$isoYZMapper->SetScalarRange(600,1200);
$isoYZActor = Graphics::VTK::Actor->new;
$isoYZActor->SetMapper($isoYZMapper);
$isoXZ = Graphics::VTK::MarchingSquares->new;
$isoXZ->SetInput($v16->GetOutput);
$isoXZ->GenerateValues(2,600,1200);
$isoXZ->SetImageRange(0,64,64,64,0,46);
$isoXZMapper = Graphics::VTK::PolyDataMapper->new;
$isoXZMapper->SetInput($isoXZ->GetOutput);
$isoXZMapper->SetScalarRange(600,1200);
$isoXZActor = Graphics::VTK::Actor->new;
$isoXZActor->SetMapper($isoXZMapper);
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($v16->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->VisibilityOff;
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->AddActor($isoXYActor);
$ren1->AddActor($isoYZActor);
$ren1->AddActor($isoXZActor);
$ren1->SetBackground(0.9,'.9','.9');
$renWin->SetSize(450,450);
$ren1->GetActiveCamera->SetPosition(324.368,284.266,-19.3293);
$ren1->GetActiveCamera->SetFocalPoint(73.5683,120.903,70.7309);
$ren1->GetActiveCamera->SetViewAngle(30);
$ren1->GetActiveCamera->SetViewUp(-0.304692,-0.0563843,-0.950781);
$ren1->GetActiveCamera->SetViewPlaneNormal(0.802383,0.522649,-0.28813);
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
#renWin SetFileName "TestMarchingSquares.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
