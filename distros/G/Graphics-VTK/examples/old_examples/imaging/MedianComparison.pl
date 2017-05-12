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
$reader = Graphics::VTK::ImageReader->new;
$reader->ReleaseDataFlagOff;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,94);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$cast = Graphics::VTK::ImageCast->new;
$cast->SetInput($reader->GetOutput);
$cast->SetOutputScalarTypeToFloat;
$shotNoiseAmplitude = 2000.0;
$shotNoiseFraction = 0.1;
$shotNoiseExtent = "0 255 0 255 0 92";
$source->ShotNoiseInclude_tcl;
$add = Graphics::VTK::ImageMathematics->new;
$add->SetInput1($cast->GetOutput);
$add->SetInput2($shotNoise->GetOutput);
$add->SetOperationToAdd;
$med = Graphics::VTK::ImageMedian3D->new;
$med->SetInput($add->GetOutput);
$med->SetKernelSize(5,5,1);
$gauss = Graphics::VTK::ImageGaussianSmooth->new;
$gauss->SetDimensionality(2);
$gauss->SetInput($add->GetOutput);
$gauss->SetStandardDeviations(2.0,2.0);
$gauss->SetRadiusFactors(2.0,2.0);
$viewer1 = Graphics::VTK::ImageViewer->new;
$viewer1->SetInput($cast->GetOutput);
$viewer1->SetZSlice(22);
$viewer1->SetColorWindow(3000);
$viewer1->SetColorLevel(1000);
$viewer2 = Graphics::VTK::ImageViewer->new;
$viewer2->SetInput($add->GetOutput);
$viewer2->SetZSlice(22);
$viewer2->SetColorWindow(3000);
$viewer2->SetColorLevel(1000);
$viewer3 = Graphics::VTK::ImageViewer->new;
$viewer3->SetInput($gauss->GetOutput);
$viewer3->SetZSlice(22);
$viewer3->SetColorWindow(3000);
$viewer3->SetColorLevel(1000);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($med->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(3000);
$viewer->SetColorLevel(1000);
# Create the GUI
$MW->withdraw;
$MW->{'.top'} = $MW->Toplevel;
$MW->{'.top.f1'} = $MW->{'.top'}->Frame;
$MW->{'.top.f2'} = $MW->{'.top'}->Frame;
$MW->{'.top.f1.r1'} = $MW->{'.top.f1'}->vtkImageViewer('-width',256,'-height',256,'-iv',$viewer1);
$MW->{'.top.f1.r2'} = $MW->{'.top.f1'}->vtkImageViewer('-width',256,'-height',256,'-iv',$viewer2);
$MW->{'.top.f2.r3'} = $MW->{'.top.f2'}->vtkImageViewer('-width',256,'-height',256,'-iv',$viewer3);
$MW->{'.top.f2.r4'} = $MW->{'.top.f2'}->vtkImageViewer('-width',256,'-height',256,'-iv',$viewer);
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
