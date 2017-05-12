#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Shift and scale an image (in that order)
# This filter is usefull for converting to a lower precision data type.
# This script test the clamp overflow feature.
#source vtkImageInclude.tcl
$reader = Graphics::VTK::ImageReader->new;
#reader DebugOn
$reader->GetOutput->ReleaseDataFlagOff;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
#[reader GetOutput] SetMemoryLimit 30
$shiftScale = Graphics::VTK::ImageShiftScale->new;
$shiftScale->SetInput($reader->GetOutput);
$shiftScale->SetShift(-1000.0);
$shiftScale->SetScale(4.0);
$shiftScale->SetOutputScalarTypeToUnsignedShort;
$shiftScale->ClampOverflowOn;
$shiftScale2 = Graphics::VTK::ImageShiftScale->new;
$shiftScale2->SetInput($shiftScale->GetOutput);
$shiftScale2->SetShift(0);
$shiftScale2->SetScale(2.0);
$viewer = Graphics::VTK::ImageViewer->new;
#viewer DebugOn
$viewer->SetInput($shiftScale2->GetOutput);
#viewer SetInput [reader GetOutput]
$viewer->SetColorWindow(1024);
$viewer->SetColorLevel(512);
#make interface
do 'WindowLevelInterface.pl';
$w = Graphics::VTK::PNMWriter->new;
$w->SetFileName('D:/vtknew/vtk/graphics/examplesTcl/mace2.ppm');
$w->SetInput($shiftScale->GetOutput);
#w Write
