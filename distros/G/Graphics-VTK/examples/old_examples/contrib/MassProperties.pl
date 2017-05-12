#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$cone = Graphics::VTK::ConeSource->new;
$cone->SetResolution(50);
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetPhiResolution(50);
$sphere->SetThetaResolution(50);
$cube = Graphics::VTK::CubeSource->new;
$cube->SetXLength(1);
$cube->SetYLength(1);
$cube->SetZLength(1);
$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($sphere->GetOutput);
$sphereMapper->GlobalImmediateModeRenderingOn;
$sphereActor = Graphics::VTK::Actor->new;
$sphereActor->SetMapper($sphereMapper);
$sphereActor->GetProperty->SetDiffuseColor(1,'.2','.4');
$coneMapper = Graphics::VTK::PolyDataMapper->new;
$coneMapper->SetInput($cone->GetOutput);
$coneMapper->GlobalImmediateModeRenderingOn;
$coneActor = Graphics::VTK::Actor->new;
$coneActor->SetMapper($coneMapper);
$coneActor->GetProperty->SetDiffuseColor('.2','.4',1);
$cubeMapper = Graphics::VTK::PolyDataMapper->new;
$cubeMapper->SetInput($cube->GetOutput);
$cubeMapper->GlobalImmediateModeRenderingOn;
$cubeActor = Graphics::VTK::Actor->new;
$cubeActor->SetMapper($cubeMapper);
$cubeActor->GetProperty->SetDiffuseColor('.2',1,'.4');
#Add the actors to the renderer, set the background and size
$sphereActor->SetPosition(-5,0,0);
$ren1->AddActor($sphereActor);
$coneActor->SetPosition(0,0,0);
$ren1->AddActor($coneActor);
$coneActor->SetPosition(5,0,0);
$ren1->AddActor($cubeActor);
#
sub MakeText
{
 my $primitive = shift;
 my $endSum;
 my $return;
 my $startSum;
 my $string;
 my $summary;
 $TriangleFilter{$primitive} = Graphics::VTK::TriangleFilter->new;
 $TriangleFilter{$primitive}->SetInput($->primitive('GetOutput'));
 $Mass{$primitive} = Graphics::VTK::MassProperties->new;
 $Mass{$primitive}->SetInput($TriangleFilter{$primitive}->GetOutput);
 $summary = $Mass{$primitive}->Print;
 $startSum = $string->first("  VolumeX",$summary);
 $endSum = $string->length($summary);
 $Text{$primitive} = Graphics::VTK::VectorText->new;
 $Text{$primitive}->SetText($string->range($summary,$startSum,$endSum));
 $TextMapper{$primitive} = Graphics::VTK::PolyDataMapper->new;
 $TextMapper{$primitive}->SetInput($Text{$primitive}->GetOutput);
 $TextActor{$primitive} = Graphics::VTK::Actor->new;
 $TextActor{$primitive}->SetMapper($TextMapper{$primitive});
 $TextActor{$primitive}->SetScale('.2','.2','.2');
 return $TextActor{$primitive};
}
$ren1->AddActor(MakeText($sphere));
$ren1->AddActor(MakeText($cube));
$ren1->AddActor(MakeText($cone));
$sphereTextActor->SetPosition($sphereActor->GetPosition);
$sphereTextActor->AddPosition(-2,-1,0);
$cubeTextActor->SetPosition($cubeActor->GetPosition);
$cubeTextActor->AddPosition(-2,-1,0);
$coneTextActor->SetPosition($coneActor->GetPosition);
$coneTextActor->AddPosition(-2,-1,0);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(786,256);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$cam1 = $ren1->GetActiveCamera;
$cam1->Dolly(4.8);
$ren1->ResetCameraClippingRange;
$iren->Initialize;
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
#renWin SetFileName "MassProperties.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
