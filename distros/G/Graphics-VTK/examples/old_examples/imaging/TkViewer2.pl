#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#source vtkImageInclude.tcl
use Graphics::VTK::Tk::vtkImageViewer;
# This script uses a vtkTkRenderWidget to create a
# Tk widget that is associated with a vtkRenderWindow.
#source TkInteractor.tcl
# Create the GUI: two renderer widgets and a quit button
$MW->withdraw;
$MW->{'.top'} = $MW->Toplevel;
$MW->{'.top.f1'} = $MW->{'.top'}->Frame;
$MW->{'.top.f1.r1'} = $MW->{'.top.f1'}->vtkImageViewer('-width',300,'-height',300);
#    BindTkRenderWidget .top.f1.r1
$MW->{'.top.btn'} = $MW->{'.top'}->Button('-text','Quit','-command',
 sub
  {
   exit();
  }
);
$MW->{'.top.f1.r1'}->pack('-side','left','-padx',3,'-pady',3,'-fill','both','-expand','t');
$MW->{'.top.f1'}->pack('-fill','both','-expand','t');
$MW->{'.top.btn'}->pack('-fill','x');
$reader = Graphics::VTK::PNMReader->new;
$reader->ReleaseDataFlagOff;
$reader->SetFileName("$VTK_DATA/earth.ppm");
$viewer = $MW->{'.top.f1.r1'}->GetImageViewer;
$viewer->SetInput($reader->GetOutput);
$viewer->SetColorWindow(256);
$viewer->SetColorLevel(127.5);
#BindTkImageViewer .top.f1.r1 

Tk->MainLoop;
