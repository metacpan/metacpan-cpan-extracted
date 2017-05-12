#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# Show the constant kernel.  Smooth an impulse function.
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#source vtkImageInclude.tcl
use Graphics::VTK::Tk::vtkImageViewer;
$reader = Graphics::VTK::ImageReader->new;
$reader->ReleaseDataFlagOff;
$reader->SetDataExtent(0,255,0,255,1,1);
$reader->SetFilePrefix("$VTK_DATA/heart");
$reader->SetDataByteOrderToBigEndian;
$cast = Graphics::VTK::ImageCast->new;
$cast->SetInput($reader->GetOutput);
$cast->SetOutputScalarTypeToFloat;
$smooth = Graphics::VTK::ImageGaussianSmooth->new;
$smooth->SetDimensionality(2);
$smooth->SetInput($cast->GetOutput);
$smooth->SetStandardDeviations(4.0,4.0);
$smooth->SetRadiusFactors(2.0,2.0);
$canvas = Graphics::VTK::ImageCanvasSource2D->new;
$canvas->SetScalarType($Graphics::VTK::FLOAT);
$canvas->SetExtent(-10,10,-10,10,0,0);
# back ground zero
$canvas->SetDrawColor(0);
$canvas->FillBox(-10,10,-10,10);
# impulse
$canvas->SetDrawColor(8000);
$canvas->DrawPoint(0,0);
$smooth2 = Graphics::VTK::ImageGaussianSmooth->new;
$smooth2->SetDimensionality(2);
$smooth2->SetInput($canvas->GetOutput);
$smooth2->SetStandardDeviations(4.0,4.0);
$smooth2->SetRadiusFactors(3.0,3.0);
$magnify = Graphics::VTK::ImageMagnify->new;
$magnify->InterpolateOff;
$magnify->SetMagnificationFactors(5,5,1);
$magnify->SetInput($smooth2->GetOutput);
$viewer2 = Graphics::VTK::ImageViewer->new;
$viewer2->SetInput($magnify->GetOutput);
$viewer2->SetColorWindow(99);
$viewer2->SetColorLevel(32);
$viewer1 = Graphics::VTK::ImageViewer->new;
$viewer1->SetInput($cast->GetOutput);
$viewer1->SetZSlice(0);
$viewer1->SetColorWindow(400);
$viewer1->SetColorLevel(200);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($smooth->GetOutput);
$viewer->SetZSlice(0);
$viewer->SetColorWindow(400);
$viewer->SetColorLevel(200);
# Create the GUI
$MW->withdraw;
$MW->{'.top'} = $MW->Toplevel;
$MW->{'.top.f1'} = $MW->{'.top'}->Frame;
$MW->{'.top.f1.r1'} = $MW->{'.top.f1'}->vtkImageViewer('-width',256,'-height',256,'-iv',$viewer1);
$MW->{'.top.f1.r2'} = $MW->{'.top.f1'}->vtkImageViewer('-width',105,'-height',105,'-iv',$viewer2);
$MW->{'.top.f1.r3'} = $MW->{'.top.f1'}->vtkImageViewer('-width',256,'-height',256,'-iv',$viewer);
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
