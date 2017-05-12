#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;
use Graphics::VTK::Tk::vtkInteractor;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Colors;
# source ../../graphics/examplesTcl/TkInteractor.tcl
$root = $MW->{'.top'} = $MW->Toplevel('-visual','truecolor 24');
$MW->{'.top'}->title("superquadric viewer");
$MW->{'.top'}->protocol('WM_DELETE_WINDOW','exit');
# create render window
$renWin = Graphics::VTK::RenderWindow->new;
$ren = $root->{'.ren'} = $root->vtkInteractor('-rw',$renWin,'-width',550,'-height',450);
#BindTkRenderWidget $ren
# create parameter sliders
$prs = $root->{'.prs'} = $root->Scale('-from',0,'-res',0.1,'-label',"phi roundness",'-to',3.5,'-orient','horizontal');
$trs = $root->{'.trs'} = $root->Scale('-from',0,'-res',0.1,'-label',"theta roundness",'-to',3.5,'-orient','horizontal');
$thicks = $root->{'.thicks'} = $root->Scale('-from',0.01,'-res',0.01,'-label',"thickness",'-to',1,'-orient','horizontal');
$rframe = $root->{'.rframe'} = $root->Frame;
$torbut = $rframe->{'.torbut'} = $rframe->Checkbutton('-text',"Toroid",'-variable',\$toroid);
$texbut = $rframe->{'.texbut'} = $rframe->Checkbutton('-text',"Texture",'-variable',\$doTexture);
$ren->grid( '-', -sticky, 'news');
$rframe->grid( $thicks, -sticky, 'news',  -padx, 10, -ipady, 5);
$rframe->grid( $rframe, -sticky, 'news');
$prs->grid( $trs, -sticky, 'news',   -padx, 10, -ipady, 5);
foreach $_ (($torbut,$texbut))
 {
  $_->pack('-padx',10,'-pady',5,'-ipadx',20,'-ipady',5,'-side','right','-anchor','s');
 }
$rframe->packPropagate('no');
$renWin1 = $ren->GetRenderWindow;
# create pipeline
$squad = Graphics::VTK::SuperquadricSource->new;
$squad->SetPhiResolution(20);
$squad->SetThetaResolution(25);
$pnmReader = Graphics::VTK::PNMReader->new;
$pnmReader->SetFileName("$VTK_DATA/earth.ppm");
$atext = Graphics::VTK::Texture->new;
$atext->SetInput($pnmReader->GetOutput);
$atext->InterpolateOn;
$blankTexture = Graphics::VTK::Texture->new;
$appendSquads = Graphics::VTK::AppendPolyData->new;
$appendSquads->AddInput($squad->GetOutput);
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($squad->GetOutput);
$mapper->ScalarVisibilityOff;
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
$actor->SetTexture($atext);
$actor->GetProperty->SetDiffuseColor(0.5,0.8,0.8);
$actor->GetProperty->SetAmbient(0.2);
$actor->GetProperty->SetAmbientColor(0.2,0.2,0.2);
#
sub setTexture
{
 my $actor = shift;
 my $texture = shift;
 my $win = shift;
 # Global Variables Declared for this function: doTexture
 if ($doTexture)
  {
   $actor->SetTexture($texture);
  }
 else
  {
   $actor->SetTexture($blankTexture);
  }
 $win->Render;
}
#
sub setPhi
{
 my $squad = shift;
 my $win = shift;
 my $phi = shift;
 $squad->SetPhiRoundness($phi);
 $win->Render;
}
#
sub setTheta
{
 my $squad = shift;
 my $win = shift;
 my $theta = shift;
 $squad->SetThetaRoundness($theta);
 $win->Render;
}
#
sub setThickness
{
 my $squad = shift;
 my $win = shift;
 my $thickness = shift;
 $squad->SetThickness($thickness);
 $win->Render;
}
#
sub setToroid
{
 my $squad = shift;
 my $scale = shift;
 my $win = shift;
 # Global Variables Declared for this function: toroid
 $squad->SetToroidal($toroid);
 if ($toroid)
  {
   $scale->configure('-state','normal','-fg','black');
  }
 else
  {
   $scale->configure('-state','disabled','-fg','gray');
  }
 $win->Render;
}
$prs->set(1.0);
$trs->set(0.7);
$thicks->set(0.3);
$toroid = 1;
$doTexture = 0;
$squad->SetPhiRoundness($prs->get);
$squad->SetThetaRoundness($trs->get);
$squad->SetToroidal($toroid);
$squad->SetThickness($thicks->get);
$squad->SetScale(1,1,1);
setTexture($actor,$atext,$renWin1);
# Create renderer stuff
$ren1 = Graphics::VTK::Renderer->new;
$ren1->SetAmbient(1,1,1);
$renWin1->AddRenderer($ren1);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($actor);
$ren1->SetBackground(0.25,0.2,0.2);
$ren1->GetActiveCamera->Zoom(1.2);
$ren1->GetActiveCamera->Elevation(40);
$ren1->GetActiveCamera->Azimuth(-20);
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
$MW->update;
$prs->configure('-command',[\&setPhi, $squad, $renWin1]);
$trs->configure('-command',[\&setTheta, $squad, $renWin1]);
$thicks->configure('-command',[\&setThickness, $squad, $renWin1]);
$torbut->configure('-command',[\&setToroid,$squad, $thicks, $renWin1]);
$texbut->configure('-command',[\&setTexture, $actor, $atext, $renWin1]);
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
