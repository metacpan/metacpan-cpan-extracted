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
$slc = Graphics::VTK::SLCReader->new;
$slc->SetFileName("$VTK_DATA/vm_foot.slc");
$types = "Char UnsignedChar Short UnsignedShort Int UnsignedInt Long UnsignedLong Float Double";
$i = 1;
foreach $vtkType ($types)
 {
  $clip{$vtkType} = Graphics::VTK::ImageClip->new;
  $clip{$vtkType}->SetInput($slc->GetOutput);
  $clip{$vtkType}->SetOutputWholeExtent(-1000,1000,-1000,1000,$i,$i);
  $i += 22;
  $castTo{$vtkType} = Graphics::VTK::ImageCast->new;
  $castTo{$vtkType}->$SetOutputScalarTypeTo{$vtkType};
  $castTo{$vtkType}->SetInput($clip{$vtkType}->GetOutput);
  $castTo{$vtkType}->ClampOverflowOn;
  $iso{$vtkType} = Graphics::VTK::ContourFilter->new;
  $iso{$vtkType}->SetInput($castTo{$vtkType}->GetOutput);
  $iso{$vtkType}->GenerateValues(1,30,30);
  $isoMapper{$vtkType} = Graphics::VTK::PolyDataMapper->new;
  $isoMapper{$vtkType}->SetInput($iso{$vtkType}->GetOutput);
  $isoMapper{$vtkType}->SetColorModeToMapScalars;
  $isoActor{$vtkType} = Graphics::VTK::Actor->new;
  $isoActor{$vtkType}->SetMapper($isoMapper{$vtkType});
  $ren1->AddActor($isoActor{$vtkType});
 }
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($slc->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->VisibilityOff;
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->GetActiveCamera->SetFocalPoint(80,130,106);
$ren1->GetActiveCamera->SetPosition(-170,-305,-131);
$ren1->GetActiveCamera->SetViewUp(0,0,-1);
$ren1->GetActiveCamera->SetViewAngle(30);
$ren1->GetActiveCamera->ComputeViewPlaneNormal;
$ren1->ResetCameraClippingRange;
$ren1->SetBackground(0.9,'.9','.9');
$renWin->SetSize(450,450);
$iren->Initialize;
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$renWin->SetFileName("contour2DAll.tcl.ppm");
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
