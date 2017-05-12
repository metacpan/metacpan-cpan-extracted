#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Threshold a volume and write it to disk.
# It then reads the new data set from disk and displays it.
# Dont forget to delete the test files after the script is finished.
#source vtkImageInclude.tcl
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,33);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$thresh = Graphics::VTK::ImageThreshold->new;
$thresh->SetInput($reader->GetOutput);
$thresh->ThresholdByUpper(1000.0);
$thresh->SetInValue(0.0);
$thresh->SetOutValue(250.0);
$thresh->ReplaceOutOn;
$thresh->SetOutputScalarTypeToUnsignedChar;
$writer = Graphics::VTK::ImageWriter->new;
$writer->SetInput($thresh->GetOutput);
$writer->SetFileName("garf.xxx");
$writer->SetFileName("test.xxx");
$writer->SetFileDimensionality(3);
$writer->SetMemoryLimit(1000);
$writer->Write;
$reader2 = Graphics::VTK::ImageReader->new;
$reader2->SetDataScalarTypeToUnsignedChar;
$reader2->ReleaseDataFlagOff;
$reader2->SetDataExtent(0,255,0,255,1,33);
$reader2->SetFileName("garf.xxx");
$reader2->SetFileName("test.xxx");
$reader2->SetFileDimensionality(3);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($reader2->GetOutput);
$viewer->SetZSlice(22);
$viewer->SetColorWindow(300);
$viewer->SetColorLevel(150);
# make interface
do 'WindowLevelInterface.pl';
