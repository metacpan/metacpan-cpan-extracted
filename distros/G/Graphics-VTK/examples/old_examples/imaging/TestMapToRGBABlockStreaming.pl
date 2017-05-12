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
$rangeStart = 0.0;
$rangeEnd = 0.2;
$LUT = Graphics::VTK::LookupTable->new;
$LUT->SetTableRange(0,1800);
$LUT->SetSaturationRange(1,1);
$LUT->SetHueRange($rangeStart,$rangeEnd);
$LUT->SetValueRange(1,1);
$LUT->SetAlphaRange(0,0);
$LUT->Build;
#
sub changeLUT
{
 # Global Variables Declared for this function: rangeStart, rangeEnd
 $rangeStart = $rangeStart + 0.1;
 $rangeEnd = $rangeEnd + 0.1;
 if ($rangeEnd > 1.0)
  {
   $rangeStart = 0.0;
   $rangeEnd = 0.2;
  }
 $LUT->SetHueRange($rangeStart,$rangeEnd);
 $LUT->Build;
}
$mapToRGBA = Graphics::VTK::ImageMapToColors->new;
$mapToRGBA->SetInput($reader->GetOutput);
$mapToRGBA->SetOutputFormatToRGBA;
$mapToRGBA->SetLookupTable($LUT);
$mapToRGBA->SetEndMethod(
 sub
  {
   changeLUT();
  }
);
$imageStreamer = Graphics::VTK::ImageDataStreamer->new;
$imageStreamer->SetInput($mapToRGBA->GetOutput);
$imageStreamer->SetMemoryLimit(65);
$imageStreamer->SetSplitModeToBlock;
# set the window/level to 255.0/127.5 to view full range
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($imageStreamer->GetOutput);
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
$pnmWriter->SetFileName("TestMapToRGBABlockStreaming.tcl.ppm");
#  pnmWriter Write
