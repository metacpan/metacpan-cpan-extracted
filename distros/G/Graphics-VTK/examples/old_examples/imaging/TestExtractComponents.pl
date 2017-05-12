#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Get Vectors from the gradent, and extract the z component.
#source vtkImageInclude.tcl
# Image pipeline
#vtkImageReader reader
#reader DebugOn
#reader SetDataByteOrderToLittleEndian
#reader SetDataExtent 0 255 0 255 1 93
#reader SetFilePrefix "$VTK_DATA/fullHead/headsq"
#reader SetDataMask 0x7fff
#vtkImageGradient gradient
#gradient SetInput [reader GetOutput]
#gradient SetFilteredAxes $VTK_IMAGE_X_AXIS $VTK_IMAGE_Y_AXIS $VTK_IMAGE_Z_AXIS
$reader = Graphics::VTK::PNMReader->new;
$reader->SetFileName("$VTK_DATA/masonry.ppm");
$extract = Graphics::VTK::ImageExtractComponents->new;
$extract->SetInput($reader->GetOutput);
$extract->SetComponents(0,1,2);
$extract->ReleaseDataFlagOff;
$viewer = Graphics::VTK::ImageViewer->new;
#viewer DebugOn
$viewer->SetInput($extract->GetOutput);
$viewer->SetZSlice(0);
$viewer->SetColorWindow(800);
$viewer->SetColorLevel(0);
#make interface
do 'WindowLevelInterface.pl';
