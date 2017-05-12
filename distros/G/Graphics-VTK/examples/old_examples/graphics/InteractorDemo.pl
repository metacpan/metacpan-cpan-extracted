#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# demostrates the features of the vtkRenderWindowInteractor
# with a tcl interface.
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# set up some strings for help.
$CameraHelp = '
Button 1 - rotate
Button 2 - pan 
Button 3 - zoom
ctrl-Button 1 - spin';
$ActorHelp = '
Button 1 - rotate
Button 2 - pan
Button 3 - scale
ctrl-Button 1 - spin
ctrl-Button 2 - dolly
';
# -----  Interface ----
$MW->withdraw;
$MW->{'.top'} = $MW->Toplevel;
$MW->{'.top.r1'} = $MW->{'.top'}->vtkInteractor('-width',400,'-height',400);
$controlFm = $MW->{'.top.f2'} = $MW->{'.top'}->Frame;
$controlFm->pack('-side','left','-padx',3,'-pady',3,'-fill','both','-expand','f');
$MW->{'.top.r1'}->pack('-side','left','-padx',3,'-pady',3,'-fill','both','-expand','t');
$controlFm->{'.camera'} = $controlFm->Radiobutton('-anchor','nw','-text',"Camera Mode <c>",'-value',"camera",'-command',
 sub
  {
   changeActorMode();
  }
,'-variable',\$actorMode);
$controlFm->{'.actor'} = $controlFm->Radiobutton('-anchor','nw','-text',"Object Mode <o>",'-value',"actor",'-command',
 sub
  {
   changeActorMode();
  }
,'-variable',\$actorMode);
$actorMode = 'camera';
#
sub changeActorMode
{
 my $iren;
 # Global Variables Declared for this function: actorMode
 if ($actorMode eq "actor")
  {
   $iren->SetActorModeToActor;
  }
 else
  {
   $iren->SetActorModeToCamera;
  }
}
$controlFm->{'.space1'} = $controlFm->Label('-text',"    ");
$controlFm->{'.joystick'} = $controlFm->Radiobutton('-anchor','nw','-text',"Joystick Mode <j>",'-value','joystick','-command',
 sub
  {
   changeTrackballMode();
  }
,'-variable',\$trackballMode);
$controlFm->{'.trackball'} = $controlFm->Radiobutton('-anchor','nw','-text',"Trackball Mode <t>",'-value','trackball','-command',
 sub
  {
   changeTrackballMode();
  }
,'-variable',\$trackballMode);
$trackballMode = 'joystick';
#
sub changeTrackballMode
{
 my $iren;
 # Global Variables Declared for this function: trackballMode
 if ($trackballMode eq "trackball")
  {
   $iren->SetTrackballModeToTrackball;
  }
 else
  {
   $iren->SetTrackballModeToJoystick;
  }
}
$controlFm->{'.space2'} = $controlFm->Label('-text',"        ");
$controlFm->{'.help'} = $controlFm->Label('-text',$CameraHelp,'-justify','left');
foreach $_ (($controlFm,$MW->{'.camera'},$controlFm,$MW->{'.actor'},$controlFm,$MW->{'.space1'},$controlFm,$MW->{'.joystick'},$controlFm,$MW->{'.trackball'},$controlFm,$MW->{'.space2'},$controlFm,$MW->{'.help'}))
 {
  $_->pack('-side','top','-fill','x');
 }
# set up the model
$renWin = $MW->{'.top.r1'}->GetRenderWindow;
$ren1 = Graphics::VTK::Renderer->new;
$renWin->AddRenderer($ren1);
$importer = Graphics::VTK::3DSImporter->new;
$importer->SetRenderWindow($renWin);
$importer->ComputeNormalsOn;
$importer->SetFileName("$VTK_DATA/Viewpoint/iflamigm.3ds");
$importer->Read;
# set up call back to change mode radio buttons
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$iren->SetCameraModeMethod(
 sub
  {
   # Global Variables Declared for this function: actorMode, controlFm
   $actorMode = 'camera';
   $controlFm->_help('configure','-text',$CameraHelp);
   $MW->update;
  }
);
$iren->SetActorModeMethod(
 sub
  {
   # Global Variables Declared for this function: actorMode, controlFm
   $actorMode = 'actor';
   $controlFm->_help('configure','-text',$ActorHelp);
   $MW->update;
  }
);
$iren->SetJoystickModeMethod(
 sub
  {
   # Global Variables Declared for this function: trackballMode
   $trackballMode = "joystick";
   $MW->update;
  }
);
$iren->SetTrackballModeMethod(
 sub
  {
   # Global Variables Declared for this function: trackballMode
   $trackballMode = 'trackball';
   $MW->update;
  }
);
$importer->GetRenderer->SetBackground(0.1,0.2,0.4);
$importer->GetRenderWindow->SetSize(400,400);
# the importer created the renderer
$renCollection = $renWin->GetRenderers;
$renCollection->InitTraversal;
$ren = $renCollection->GetNextItem;
# change view up to +z
$ren->GetActiveCamera->SetPosition(0,1,0);
$ren->GetActiveCamera->SetFocalPoint(0,0,0);
$ren->GetActiveCamera->ComputeViewPlaneNormal;
$ren->GetActiveCamera->SetViewUp(0,0,1);
# let the renderer compute good position and focal point
$ren->ResetCamera;
$ren->GetActiveCamera->Dolly(1.4);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
