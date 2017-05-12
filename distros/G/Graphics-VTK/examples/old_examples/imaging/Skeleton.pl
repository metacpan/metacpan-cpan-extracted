#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# A script to test the threshold filter.
# Values above 2000 are set to 255.
# Values below 2000 are set to 0.
#source vtkImageInclude.tcl
use Graphics::VTK::Tk::vtkImageViewer;
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
#reader DebugOn
$thresh = Graphics::VTK::ImageThreshold->new;
$thresh->SetInput($reader->GetOutput);
$thresh->SetOutputScalarTypeToUnsignedChar;
$thresh->ThresholdByUpper(1500.0);
$thresh->SetInValue(255);
$thresh->SetOutValue(0);
$thresh->ReleaseDataFlagOff;
$my_close = Graphics::VTK::ImageOpenClose3D->new;
$my_close->SetInput($thresh->GetOutput);
$my_close->SetOpenValue(0);
$my_close->SetCloseValue(255);
$my_close->SetKernelSize(5,5,3);
$my_close->ReleaseDataFlagOff;
$skeleton1 = Graphics::VTK::ImageSkeleton2D->new;
#skeleton1 BypassOn
$skeleton1->SetInput($my_close->GetOutput);
$skeleton1->SetPrune(1);
$skeleton1->SetNumberOfIterations(20);
$skeleton1->ReleaseDataFlagOff;
$viewer1 = Graphics::VTK::ImageViewer->new;
$viewer1->SetInput($my_close->GetOutput);
$viewer1->SetColorWindow(5);
$viewer1->SetColorLevel(1);
$viewer = Graphics::VTK::ImageViewer->new;
#viewer SetInput [magnify GetOutput]
$viewer->SetInput($skeleton1->GetOutput);
$viewer->SetColorWindow(5);
$viewer->SetColorLevel(1);
# Create the GUI
$MW->withdraw;
$MW->{'.top'} = $MW->Toplevel;
$MW->{'.top.f1'} = $MW->{'.top'}->Frame;
$MW->{'.top.f2'} = $MW->{'.top'}->Frame;
$MW->{'.top.f1.r1'} = $MW->{'.top.f1'}->vtkImageViewer('-width',256,'-height',256,'-iv',$viewer1);
$MW->{'.top.f1.r2'} = $MW->{'.top.f1'}->vtkImageViewer('-width',256,'-height',256,'-iv',$viewer);
$MW->{'.top.btn'} = $MW->{'.top'}->Button('-text','Quit','-command',
 sub
  {
   exit();
  }
);
foreach $_ (($MW->{'.top.f1.r1'},$MW->{'.top.f1.r2'}))
 {
  $_->pack('-side','left','-padx',3,'-pady',3,'-expand','t');
 }
$MW->{'.top.f1'}->pack('-fill','both','-expand','t');
$MW->{'.top.btn'}->pack('-fill','x');
#BindTkImageViewer .top.f1.r1 
#BindTkImageViewer .top.f1.r2

Tk->MainLoop;
