#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Test the vtkImageCast filter.
# Cast the shorts to unsinged chars.  This will cause overflow artifacts
# because the data does not fit into 8 bits.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
#reader ReleaseDataFlagOff
#reader DebugOn
$cast = Graphics::VTK::ImageCast->new;
$cast->SetInput($reader->GetOutput);
$cast->SetOutputScalarType($Graphics::VTK::UNSIGNED_CHAR);
$cast->ClampOverflowOn;
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($cast->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(200);
$viewer->SetColorLevel(60);
#viewer DebugOn
$viewer->Render;
# make interface
do 'WindowLevelInterface.pl';
