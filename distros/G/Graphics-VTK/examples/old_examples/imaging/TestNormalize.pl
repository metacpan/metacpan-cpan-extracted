#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This script is for testing the normalize filter.
#source vtkImageInclude.tcl
use Graphics::VTK::Tk::vtkImageViewer;
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
#reader DebugOn
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$gradient = Graphics::VTK::ImageGradient->new;
$gradient->SetInput($reader->GetOutput);
$gradient->SetDimensionality(3);
$norm = Graphics::VTK::ImageNormalize->new;
$norm->SetInput($gradient->GetOutput);
$viewer = Graphics::VTK::ImageViewer->new;
#viewer DebugOn
$viewer->SetInput($norm->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(1.0);
$viewer->SetColorLevel(0.5);
# Create the GUI: two renderer widgets and a quit button
$MW->withdraw;
$MW->{'.top'} = $MW->Toplevel;
$MW->{'.top.f1'} = $MW->{'.top'}->Frame;
$MW->{'.top.f1.r1'} = $MW->{'.top.f1'}->vtkImageViewer('-width',256,'-height',256,'-iv',$viewer);
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
#BindTkImageViewer .top.f1.r1 

Tk->MainLoop;
