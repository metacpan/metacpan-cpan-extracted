#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
use Graphics::VTK::Tk::vtkImageViewer;
$MW = {};

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#
#
#
# This script uses a vtkTkRenderWidget to create a
# Tk widget that is associated with a vtkRenderWindow.
#source TkInteractor.tcl
#
$reader = Graphics::VTK::PNMReader->new;
$reader->ReleaseDataFlagOff;
$reader->SetFileName("$VTK_DATA/earth.ppm");
#
#$viewer = Graphics::VTK::ImageViewer->new;
#$viewer->SetInput($reader->GetOutput);
#$viewer->SetColorWindow(256);
#$viewer->SetColorLevel(127.5);
#$viewer->GetImageWindow->DoubleBufferOn;
#
# Create the GUI: two renderer widgets and a quit button
#
$MW->{'.top'} = Tk::MainWindow->new;
#
$MW->{'.top.f1'} = $MW->{'.top'}->Frame;
#
#$MW->{'.top.f1.r1'} = $MW->{'.top.f1'}->vtkImageViewer('-width',512,'-height',256,'-iv',$viewer);
#    BindTkRenderWidget .top.f1.r1
#
$MW->{'.top.f1.r1'} = $MW->{'.top.f1'}->vtkImageViewer('-width',512,'-height',256);
print "Done\n";
$viewer = $MW->{'.top.f1.r1'}->GetImageViewer;
$viewer->SetInput($reader->GetOutput);
$viewer->SetColorWindow(256);
$viewer->SetColorLevel(127.5);
$viewer->GetRenderWindow->DoubleBufferOn;


$MW->{'.top.btn'} = $MW->{'.top'}->Button('-text','Quit','-command',
 sub
  {
   exit();
  }
);
#
$MW->{'.top.f1.r1'}->pack('-side','left','-padx',3,'-pady',3,'-fill','both','-expand','t');
$MW->{'.top.f1'}->pack('-fill','both','-expand','t');
$MW->{'.top.btn'}->pack('-fill','x');
#
#
#

Tk->MainLoop;
