#!/usr/local/bin/perl -w
#
use Graphics::VTK;

# Tst the OpenClose3D filter.
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
#reader DebugOn
$thresh = Graphics::VTK::ImageThreshold->new;
$thresh->SetInput($reader->GetOutput);
$thresh->SetOutputScalarTypeToUnsignedChar;
$thresh->ThresholdByUpper(2000.0);
$thresh->SetInValue(255);
$thresh->SetOutValue(0);
$thresh->ReleaseDataFlagOff;
$my_close = Graphics::VTK::ImageOpenClose3D->new;
$my_close->SetInput($thresh->GetOutput);
$my_close->SetOpenValue(0);
$my_close->SetCloseValue(255);
$my_close->SetKernelSize(5,5,3);
$my_close->ReleaseDataFlagOff;
# for coverage (we could compare results to see if they are correct).
$my_close->DebugOn;
$my_close->DebugOff;
$my_close->GetOutput;
$my_close->GetCloseValue;
$my_close->GetOpenValue;
#my_close SetProgressMethod {set pro [my_close GetProgress]; puts "Completed $pro"; flush stdout}
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($my_close->GetOutput);
$viewer->SetZSlice(2);
$viewer->SetColorWindow(255);
$viewer->SetColorLevel(127.5);
# make interface
do 'WindowLevelInterface.pl';
