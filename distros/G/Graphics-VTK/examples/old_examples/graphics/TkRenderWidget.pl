#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This script uses a vtkTkRenderWidget to create a
# Tk widget that is associated with a vtkRenderWindow.
use Graphics::VTK::Tk::vtkInteractor;
# Load in standard bindings for interactor
# Create the GUI: two renderer widgets and a quit button
$MW->withdraw;
$MW->{'.top'} = $MW->Toplevel;
$MW->{'.top.f1'} = $MW->{'.top'}->Frame;
$MW->{'.top.f1.r1'} = $MW->{'.top.f1'}->vtkInteractor('-width',600,'-height',600);
#    BindTkRenderWidget .top.f1.r1
#vtkTkRenderWidget .top.f1.r2 -width 300 -height 300 
#    BindTkRenderWidget .top.f1.r2
$MW->{'.top.btn'} = $MW->{'.top'}->Button('-text','Quit','-command',
 sub
  {
   exit();
  }
);
$MW->{'.top.f1.r1'}->pack('-side','left','-padx',3,'-pady',3,'-fill','both','-expand','t');
#pack .top.f1.r2 -side left -padx 3 -pady 3 -fill both -expand t
$MW->{'.top.f1'}->pack('-fill','both','-expand','t');
$MW->{'.top.btn'}->pack('-fill','x');
# Get the render window associated with the widget.
$renWin1 = $MW->{'.top.f1.r1'}->GetRenderWindow;
$ren1 = Graphics::VTK::Renderer->new;
$renWin1->AddRenderer($ren1);
#set renWin2 [.top.f1.r2 GetRenderWindow]
#vtkRenderer ren2
#$renWin2 AddRenderer ren2
# create a sphere source and actor
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetPhiResolution(160);
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
$spikeMapper->ImmediateModeRenderingOn;
$spikeActor = Graphics::VTK::LODActor->new;
$spikeActor->SetMapper($spikeMapper);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($sphereActor);
$ren1->AddActor($spikeActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin1->SetSize(300,300);
#
sub TkCheckAbort
{
 my $foo;
 # Global Variables Declared for this function: renWin1
 $foo = $renWin1->GetEventPending;
 $renWin1->SetAbortRender(1) if ($foo != 0);
}
$renWin1->SetAbortCheckMethod(
 sub
  {
   TkCheckAbort();
  }
);
#ren2 AddActor sphereActor
#ren2 AddActor spikeActor
#ren2 SetBackground 0.1 0.2 0.4
#$renWin2 SetSize 300 300

Tk->MainLoop;
