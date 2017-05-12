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
$reader = Graphics::VTK::PNMReader->new;
$reader->SetFileName("$VTK_DATA/vtks.pgm");
$fft = Graphics::VTK::ImageFFT->new;
$fft->SetFilteredAxes($VTK_IMAGE_X_AXIS,$VTK_IMAGE_Y_AXIS);
$fft->SetInput($reader->GetOutput);
$mag = Graphics::VTK::ImageMagnitude->new;
$mag->SetInput($fft->GetOutput);
$center = Graphics::VTK::ImageFourierCenter->new;
$center->SetInput($mag->GetOutput);
$center->SetFilteredAxes($VTK_IMAGE_X_AXIS,$VTK_IMAGE_Y_AXIS);
$compress = Graphics::VTK::ImageLogarithmicScale->new;
$compress->SetInput($center->GetOutput);
$compress->SetConstant(15);
$viewer1 = Graphics::VTK::ImageViewer->new;
$viewer1->SetInput($reader->GetOutput);
$viewer1->SetColorWindow(160);
$viewer1->SetColorLevel(120);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($compress->GetOutput);
$viewer->SetColorWindow(160);
$viewer->SetColorLevel(120);
# Create the GUI
$MW->withdraw;
$MW->{'.top'} = $MW->Toplevel;
$MW->{'.top.f1'} = $MW->{'.top'}->Frame;
$MW->{'.top.f1.r1'} = $MW->{'.top.f1'}->vtkImageViewer('-width',320,'-height',160,'-iv',$viewer1);
$MW->{'.top.f1.r2'} = $MW->{'.top.f1'}->vtkImageViewer('-width',320,'-height',160,'-iv',$viewer);
$MW->{'.top.btn'} = $MW->{'.top'}->Button('-text','Quit','-command',
 sub
  {
   exit();
  }
);
foreach $_ (($MW->{'.top.f1.r1'},$MW->{'.top.f1.r2'}))
 {
  $_->pack('-side','top','-padx',3,'-pady',3,'-expand','t');
 }
$MW->{'.top.f1'}->pack('-fill','both','-expand','t');
$MW->{'.top.btn'}->pack('-fill','x');
#BindTkImageViewer .top.f1.r1 
#BindTkImageViewer .top.f1.r2

Tk->MainLoop;
