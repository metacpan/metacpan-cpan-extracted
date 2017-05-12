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
$source->vtkHistogramWidget_tcl;
# This script uses a vtkTkRenderWidget to create a
# Tk widget that is associated with a vtkRenderWindow.
#source TkInteractor.tcl
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
# named viewer2 so regresion test will find the histogram window
$viewer2 = Graphics::VTK::ImageViewer->new;
$viewer2->SetInput($reader->GetOutput);
$viewer2->SetZSlice(14);
$viewer2->SetColorWindow(2000);
$viewer2->SetColorLevel(1000);
# Create the GUI: two renderer widgets and a quit button
$MW->withdraw;
$MW->{'.top'} = $MW->Toplevel;
$MW->{'.top.f1'} = $MW->{'.top'}->Frame;
$MW->{'.top.f1.r1'} = $MW->{'.top.f1'}->vtkImageViewer('-width',256,'-height',256,'-iv',$viewer2);
$hist = $MW->{'.top.f1.r2'} = Graphics::VTK::HistogramWidget->new;
$HistogramWidgetSetInput->_hist($reader->GetOutput);
$HistogramWidgetSetExtent->_hist(0,255,0,255,14,14);
# let the regression test find the histogram window
$viewer = $hist->GetImageViewer;
($xMin,$xMax,$yMin,$yMax,$zMin,$zMax) = $reader->GetOutput->GetWholeExtent;
$MW->{'.top.btn'} = $MW->{'.top'}->Button('-text','Quit','-command',
 sub
  {
   exit();
  }
);
$MW->{'.top.slice'} = $MW->{'.top'}->Scale('-from',$zMin,'-label',"Z Slice",'-to',$zMax,'-variable',\$sliceNumber,'-command',
 sub
  {
   SetSlice();
  }
,'-orient','horizontal');
$sliceNumber = 14;
#
sub SetSlice
{
 my $slice = shift;
 my $HistogramWidgetRender;
 my $HistogramWidgetSetExtent;
 # Global Variables Declared for this function: hist, xMin, xMax, yMin, yMax
 $viewer2->SetZSlice($slice);
 $viewer2->Render;
 $HistogramWidgetSetExtent->_hist($xMin,$xMax,$yMin,$yMax,$slice,$slice);
 $HistogramWidgetRender->_hist;
}
$MW->{'.top.f1.r1'}->pack('-side','left','-padx',3,'-pady',3,'-fill','both','-expand','f');
$hist->pack('-side','left','-padx',3,'-pady',3,'-fill','both','-expand','t');
$MW->{'.top.f1'}->pack('-fill','both','-expand','t');
foreach $_ (($MW->{'.top.slice'},$MW->{'.top.btn'}))
 {
  $_->pack('-fill','x','-expand','f');
 }
#BindTkImageViewer .top.f1.r1 
$HistogramWidgetBind->_top_f1_r2;

Tk->MainLoop;
