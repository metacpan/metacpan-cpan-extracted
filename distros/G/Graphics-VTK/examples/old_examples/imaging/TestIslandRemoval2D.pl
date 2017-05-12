#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# A script to test the island removal filter.
# first the image is thresholded, then small islands are removed.
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
$thresh->ThresholdByUpper(2000.0);
$thresh->SetInValue(255);
$thresh->SetOutValue(0);
$thresh->ReleaseDataFlagOff;
$island = Graphics::VTK::ImageIslandRemoval2D->new;
$island->SetInput($thresh->GetOutput);
$island->SetIslandValue(255);
$island->SetReplaceValue(128);
$island->SetAreaThreshold(100);
$island->SquareNeighborhoodOn;
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($island->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(255);
$viewer->SetColorLevel(127.5);
#viewer DebugOn
# make interface
do 'WindowLevelInterface.pl';
