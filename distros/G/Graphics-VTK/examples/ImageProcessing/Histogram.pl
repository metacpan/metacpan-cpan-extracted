#!/usr/local/bin/perl -w
#
use Graphics::VTK;


use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;
use Graphics::VTK::Tk::vtkImageViewer;
use HistogramWidget;

# This script uses a vtkTkRenderWidget to create a
# Tk widget that is associated with a vtkRenderWindow.
#source TkInteractor.tcl

$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,63,0,63,1,93);
$reader->SetFilePrefix("$VTK_DATA_ROOT/Data/headsq/quarter");
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

$MW->{'.top.f1.r1'} = $MW->{'.top.f1'}->vtkImageViewer('-width',64,'-height',64,
		-iv => $viewer2);


$hist = $MW->{'.top.f1.r2'} =  $MW->{'.top.f1'}->HistogramWidget;
$hist->SetInput($reader->GetOutput);
$hist->SetExtent(0,63,0,63,14,14);

# let the regression test find the histogram window
#$viewer = $hist->GetImageViewer;


($xMin,$xMax,$yMin,$yMax,$zMin,$zMax) = $reader->GetOutput->GetWholeExtent;

$MW->{'.top.btn'} = $MW->{'.top'}->Button('-text','Quit','-command',
 sub
  {
   # Make sure the vtkImageViewer we supplied is destroyed before the vtkImageViewer Widget
   #  to avoid a warning message.
   $viewer2 = undef;
   $MW->{'.top.f1.r1'}->configure(-iv => undef);
   exit();
  }
);
$MW->{'.top.slice'} = $MW->{'.top'}->Scale('-from',$zMin,'-label',"Z Slice",'-to',$zMax,'-variable',\$sliceNumber,'-command',
   \&SetSlice,
,'-orient','horizontal');
$sliceNumber = 14;

#
sub SetSlice
{
 my $slice = shift;
 # Global Variables Declared for this function: hist, xMin, xMax, yMin, yMax

 $viewer2->SetZSlice($slice);
 $viewer2->Render;

 $hist->SetExtent($xMin,$xMax,$yMin,$yMax,$slice,$slice);
 $hist->HistogramWidgetRender;
}

$MW->{'.top.f1.r1'}->pack('-side','left','-padx',3,'-pady',3,'-fill','both','-expand','no');
$hist->pack('-side','left','-padx',3,'-pady',3,'-fill','both','-expand','yes');
$MW->{'.top.f1'}->pack('-fill','both','-expand','yes');
foreach $_ (($MW->{'.top.slice'},$MW->{'.top.btn'}))
 {
  $_->pack('-fill','x','-expand','no');
 }


Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
