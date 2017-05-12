#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Demonstrate how to use picking and annotation
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# create a sphere source and actor
$sphere = Graphics::VTK::SphereSource->new;
$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($sphere->GetOutput);
$sphereMapper->GlobalImmediateModeRenderingOn;
$sphereActor = Graphics::VTK::LODActor->new;
$sphereActor->SetMapper($sphereMapper);
# create the spikes using a cone source and the sphere source
$cone = Graphics::VTK::ConeSource->new;
$glyph = Graphics::VTK::Glyph3D->new;
$glyph->SetInput($sphere->GetOutput);
$glyph->SetSource($cone->GetOutput);
$glyph->SetVectorModeToUseNormal;
$glyph->SetScaleModeToScaleByVector;
$glyph->SetScaleFactor(0.25);
$spikeMapper = Graphics::VTK::PolyDataMapper->new;
$spikeMapper->SetInput($glyph->GetOutput);
$spikeActor = Graphics::VTK::LODActor->new;
$spikeActor->SetMapper($spikeMapper);
# Picking stuff
$picker = Graphics::VTK::CellPicker->new;
$picker->SetEndPickMethod(
 sub
  {
   annotatePick();
  }
);
$textMapper = Graphics::VTK::TextMapper->new;
$textMapper->SetFontFamilyToArial;
$textMapper->SetFontSize(10);
$textMapper->BoldOn;
$textMapper->ShadowOn;
$textActor = Graphics::VTK::Actor2D->new;
$textActor->VisibilityOff;
$textActor->SetMapper($textMapper);
$textActor->GetProperty->SetColor(1,0,0);
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$iren->SetPicker($picker);
# Add the actors to the renderer, set the background and size
$ren1->AddActor2D($textActor);
$ren1->AddActor($sphereActor);
$ren1->AddActor($spikeActor);
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
$cam1->Zoom(1.4);
$iren->Initialize;
$renWin->SetFileName("annotatePick.tcl.ppm");
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
#
sub annotatePick
{
 my $pickPos;
 my $selPt;
 my $x;
 my $xp;
 my $y;
 my $yp;
 my $zp;
 if ($picker->GetCellId < 0)
  {
   $textActor->VisibilityOff;
  }
 else
  {
   $selPt = $picker->GetSelectionPoint;
   $x = $selPt[0];
   $y = $selPt[1];
   $pickPos = $picker->GetPickPosition;
   $xp = $pickPos[0];
   $yp = $pickPos[1];
   $zp = $pickPos[2];
   $textMapper->SetInput("($xp, $yp, $zp)");
   $textActor->SetPosition($x,$y);
   $textActor->VisibilityOn;
  }
 $renWin->Render;
}
$picker->Pick(85,126,0,$ren1);
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
