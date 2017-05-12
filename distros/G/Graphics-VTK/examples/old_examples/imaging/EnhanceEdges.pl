#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This script subtracts the 2D laplacian from an image to enhance the edges.
#source vtkImageInclude.tcl
use Graphics::VTK::Tk::vtkImageViewer;
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
#reader DebugOn
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$cast = Graphics::VTK::ImageCast->new;
$cast->SetInput($reader->GetOutput);
$cast->SetOutputScalarTypeToFloat;
$lap = Graphics::VTK::ImageLaplacian->new;
$lap->SetInput($cast->GetOutput);
$lap->SetDimensionality(3);
$subtract = Graphics::VTK::ImageMathematics->new;
$subtract->SetOperationToSubtract;
$subtract->SetInput1($cast->GetOutput);
$subtract->SetInput2($lap->GetOutput);
$subtract->ReleaseDataFlagOff;
#subtract BypassOn
$viewer1 = Graphics::VTK::ImageViewer->new;
$viewer1->SetInput($cast->GetOutput);
$viewer1->SetZSlice(22);
$viewer1->SetColorWindow(2000);
$viewer1->SetColorLevel(1000);
$viewer2 = Graphics::VTK::ImageViewer->new;
$viewer2->SetInput($lap->GetOutput);
$viewer2->SetZSlice(22);
$viewer2->SetColorWindow(1000);
$viewer2->SetColorLevel(0);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($subtract->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(2000);
$viewer->SetColorLevel(1000);
# Create the GUI
$MW->withdraw;
$MW->{'.top'} = $MW->Toplevel;
$MW->{'.top.f1'} = $MW->{'.top'}->Frame;
$MW->{'.top.f1.r1'} = $MW->{'.top.f1'}->vtkImageViewer('-width',250,'-height',256,'-iv',$viewer1);
$MW->{'.top.f1.r2'} = $MW->{'.top.f1'}->vtkImageViewer('-width',250,'-height',256,'-iv',$viewer2);
$MW->{'.top.f1.r3'} = $MW->{'.top.f1'}->vtkImageViewer('-width',250,'-height',256,'-iv',$viewer);
$MW->{'.top.btn'} = $MW->{'.top'}->Button('-text','Quit','-command',
 sub
  {
   exit();
  }
);
foreach $_ (($MW->{'.top.f1.r1'},$MW->{'.top.f1.r2'},$MW->{'.top.f1.r3'}))
 {
  $_->pack('-side','left','-padx',3,'-pady',3,'-expand','t');
 }
$MW->{'.top.f1'}->pack('-fill','both','-expand','t');
$MW->{'.top.btn'}->pack('-fill','x');
#BindTkImageViewer .top.f1.r1 
#BindTkImageViewer .top.f1.r2
#BindTkImageViewer .top.f1.r3 

Tk->MainLoop;
