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
$canvas = Graphics::VTK::ImageCanvasSource2D->new;
$canvas->SetScalarType($Graphics::VTK::FLOAT);
$canvas->SetExtent(0,255,0,255,0,0);
# back ground zero
$canvas->SetDrawColor(0);
$canvas->FillBox(0,255,0,255);
$canvas->SetDrawColor(255);
$canvas->FillBox(30,225,30,225);
$canvas->SetDrawColor(0);
$canvas->FillBox(60,195,60,195);
$canvas->SetDrawColor(255);
$canvas->FillTube(100,100,154,154,40.0);
$canvas->SetDrawColor(0);
$canvas->DrawSegment(45,45,45,210);
$canvas->DrawSegment(45,210,210,210);
$canvas->DrawSegment(210,210,210,45);
$canvas->DrawSegment(210,45,45,45);
$canvas->DrawSegment(100,150,150,100);
$canvas->DrawSegment(110,160,160,110);
$canvas->DrawSegment(90,140,140,90);
$canvas->DrawSegment(120,170,170,120);
$canvas->DrawSegment(80,130,130,80);
$shotNoiseAmplitude = 255.0;
$shotNoiseFraction = 0.1;
$shotNoiseExtent = "0 255 0 255 0 0";
$source->ShotNoiseInclude_tcl;
$add = Graphics::VTK::ImageMathematics->new;
$add->SetInput1($shotNoise->GetOutput);
$add->SetInput2($canvas->GetOutput);
$add->SetOperationToAdd;
$median = Graphics::VTK::ImageMedian3D->new;
$median->SetInput($add->GetOutput);
$median->SetKernelSize(5,5,1);
$hybrid1 = Graphics::VTK::ImageHybridMedian2D->new;
$hybrid1->SetInput($add->GetOutput);
$hybrid2 = Graphics::VTK::ImageHybridMedian2D->new;
$hybrid2->SetInput($hybrid1->GetOutput);
$viewer1 = Graphics::VTK::ImageViewer->new;
$viewer1->SetInput($canvas->GetOutput);
$viewer1->SetColorWindow(256);
$viewer1->SetColorLevel(127.5);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($add->GetOutput);
$viewer->SetColorWindow(256);
$viewer->SetColorLevel(127.5);
$viewer3 = Graphics::VTK::ImageViewer->new;
$viewer3->SetInput($hybrid2->GetOutput);
$viewer3->SetColorWindow(256);
$viewer3->SetColorLevel(127.5);
$viewer4 = Graphics::VTK::ImageViewer->new;
$viewer4->SetInput($median->GetOutput);
$viewer4->SetColorWindow(256);
$viewer4->SetColorLevel(127.5);
# Create the GUI
$MW->withdraw;
$MW->{'.top'} = $MW->Toplevel;
$MW->{'.top.f1'} = $MW->{'.top'}->Frame;
$MW->{'.top.f2'} = $MW->{'.top'}->Frame;
$MW->{'.top.f1.r1'} = $MW->{'.top.f1'}->vtkImageViewer('-width',256,'-height',256,'-iv',$viewer1);
$MW->{'.top.f1.r2'} = $MW->{'.top.f1'}->vtkImageViewer('-width',256,'-height',256,'-iv',$viewer);
$MW->{'.top.f2.r3'} = $MW->{'.top.f2'}->vtkImageViewer('-width',256,'-height',256,'-iv',$viewer3);
$MW->{'.top.f2.r4'} = $MW->{'.top.f2'}->vtkImageViewer('-width',256,'-height',256,'-iv',$viewer4);
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
foreach $_ (($MW->{'.top.f2.r3'},$MW->{'.top.f2.r4'}))
 {
  $_->pack('-side','left','-padx',3,'-pady',3,'-expand','t');
 }
foreach $_ (($MW->{'.top.f1'},$MW->{'.top.f2'}))
 {
  $_->pack('-fill','both','-expand','t');
 }
$MW->{'.top.btn'}->pack('-fill','x');
#BindTkImageViewer .top.f1.r1 
#BindTkImageViewer .top.f1.r2
#BindTkImageViewer .top.f2.r3
#BindTkImageViewer .top.f2.r4

Tk->MainLoop;
