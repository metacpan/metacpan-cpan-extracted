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
$fft = Graphics::VTK::ImageFFT->new;
$fft->SetFilteredAxes($VTK_IMAGE_X_AXIS,$VTK_IMAGE_Y_AXIS);
$fft->SetInput($cast->GetOutput);
$fft->ReleaseDataFlagOff;
$highPass1 = Graphics::VTK::ImageIdealHighPass->new;
$highPass1->SetInput($fft->GetOutput);
$highPass1->SetXCutOff(0.15);
$highPass1->SetYCutOff(0.15);
$highPass1->ReleaseDataFlagOff;
$highPass2 = Graphics::VTK::ImageButterworthHighPass->new;
$highPass2->SetInput($fft->GetOutput);
$highPass2->SetOrder(2);
$highPass2->SetXCutOff(0.15);
$highPass2->SetYCutOff(0.15);
$highPass2->ReleaseDataFlagOff;
$rfft1 = Graphics::VTK::ImageRFFT->new;
$rfft1->SetFilteredAxes($VTK_IMAGE_X_AXIS,$VTK_IMAGE_Y_AXIS);
$rfft1->SetInput($highPass1->GetOutput);
$rfft2 = Graphics::VTK::ImageRFFT->new;
$rfft2->SetFilteredAxes($VTK_IMAGE_X_AXIS,$VTK_IMAGE_Y_AXIS);
$rfft2->SetInput($highPass2->GetOutput);
$real1 = Graphics::VTK::ImageExtractComponents->new;
$real1->SetInput($rfft1->GetOutput);
$real1->SetComponents(0);
$real2 = Graphics::VTK::ImageExtractComponents->new;
$real2->SetInput($rfft2->GetOutput);
$real2->SetComponents(0);
$viewer1 = Graphics::VTK::ImageViewer->new;
$viewer1->SetInput($highPass1->GetOutput);
$viewer1->SetZSlice(22);
$viewer1->SetColorWindow(10000);
$viewer1->SetColorLevel(5000);
$viewer2 = Graphics::VTK::ImageViewer->new;
$viewer2->SetInput($highPass2->GetOutput);
$viewer2->SetZSlice(22);
$viewer2->SetColorWindow(10000);
$viewer2->SetColorLevel(5000);
$viewer3 = Graphics::VTK::ImageViewer->new;
$viewer3->SetInput($real1->GetOutput);
$viewer3->SetZSlice(22);
$viewer3->SetColorWindow(500);
$viewer3->SetColorLevel(0);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($real2->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(500);
$viewer->SetColorLevel(0);
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
