#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Make an image larger by repeating the data.  Tile.
#source vtkImageInclude.tcl
use Graphics::VTK::Tk::vtkImageViewer;
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,94);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
#reader DebugOn
$pad1 = Graphics::VTK::ImageMirrorPad->new;
$pad1->SetInput($reader->GetOutput);
$pad1->SetOutputWholeExtent(-127,383,-127,383,0,93);
$pad2 = Graphics::VTK::ImageConstantPad->new;
$pad2->SetInput($reader->GetOutput);
$pad2->SetOutputWholeExtent(-127,383,-127,383,0,93);
$pad2->SetConstant(800);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($pad1->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(2000);
$viewer->SetColorLevel(1000);
$viewer->GetActor2D->SetDisplayPosition(127,127);
$viewer2 = Graphics::VTK::ImageViewer->new;
$viewer2->SetInput($pad2->GetOutput);
$viewer2->SetZSlice(22);
$viewer2->SetColorWindow(2000);
$viewer2->SetColorLevel(1000);
$viewer2->GetActor2D->SetDisplayPosition(127,127);
# Create the GUI
$MW->withdraw;
$MW->{'.top'} = $MW->Toplevel;
$MW->{'.top.f1'} = $MW->{'.top'}->Frame;
$MW->{'.top.f1.r1'} = $MW->{'.top.f1'}->vtkImageViewer('-width',360,'-height',512,'-iv',$viewer);
$MW->{'.top.f1.r2'} = $MW->{'.top.f1'}->vtkImageViewer('-width',360,'-height',512,'-iv',$viewer2);
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
