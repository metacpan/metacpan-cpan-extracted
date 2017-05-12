#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#source vtkImageInclude.tcl
$reader = Graphics::VTK::ImageReader->new;
$reader->ReleaseDataFlagOff;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$LUT = Graphics::VTK::LookupTable->new;
$LUT->SetTableRange(0,1800);
$LUT->SetSaturationRange(1,1);
$LUT->SetHueRange(0,1);
$LUT->SetValueRange(1,1);
$LUT->SetAlphaRange(0,0);
$LUT->Build;
$mapToRGBA = Graphics::VTK::ImageMapToColors->new;
$mapToRGBA->SetInput($reader->GetOutput);
$mapToRGBA->SetOutputFormatToRGBA;
$mapToRGBA->SetLookupTable($LUT);
# set the window/level to 255.0/127.5 to view full range
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($mapToRGBA->GetOutput);
$viewer->SetColorWindow(255.0);
$viewer->SetColorLevel(127.5);
$viewer->SetZSlice(50);
$viewer->Render;
#make interface
do 'WindowLevelInterface.pl';
$windowToimage = Graphics::VTK::WindowToImageFilter->new;
$windowToimage->SetInput($viewer->GetImageWindow);
$pnmWriter = Graphics::VTK::PNMWriter->new;
$pnmWriter->SetInput($windowToimage->GetOutput);
$pnmWriter->SetFileName("TestMapToRGBA.tcl.ppm");
#  pnmWriter Write
