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
# This script tests the Append filter that puts two images together.
$reader1 = Graphics::VTK::PNMReader->new;
$reader1->ReleaseDataFlagOff;
$reader1->SetFileName("$VTK_DATA/earth.ppm");
$reader2 = Graphics::VTK::PNMReader->new;
$reader2->ReleaseDataFlagOff;
$reader2->SetFileName("$VTK_DATA/masonry.ppm");
$appendF = Graphics::VTK::ImageAppend->new;
$appendF->SetAppendAxis(0);
$appendF->AddInput($reader1->GetOutput);
$appendF->AddInput($reader2->GetOutput);
# clip to make sure translation of extents is working correctly
$clip = Graphics::VTK::ImageClip->new;
$clip->SetInput($appendF->GetOutput);
$clip->SetOutputWholeExtent(100,700,20,235,0,0);
#clip SetOutputWholeExtent 0 767 20 230 0 0
$clip->ReleaseDataFlagOff;
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($clip->GetOutput);
$viewer->SetColorWindow(256);
$viewer->SetColorLevel(127.5);
# Create the GUI: two renderer widgets and a quit button
$MW->withdraw;
$MW->{'.top'} = $MW->Toplevel;
$MW->{'.top.f1'} = $MW->{'.top'}->Frame;
$MW->{'.top.f1.r1'} = $MW->{'.top.f1'}->vtkImageViewer('-width',768,'-height',256,'-iv',$viewer);
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
