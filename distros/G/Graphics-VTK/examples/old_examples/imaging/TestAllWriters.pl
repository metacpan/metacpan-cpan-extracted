#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This script reads an image and writes it in several formats
#source vtkImageInclude.tcl
# Image pipeline
$image = Graphics::VTK::BMPReader->new;
$image->SetFileName("$VTK_DATA/beach.bmp");
$image->Update;
$sp = Graphics::VTK::StructuredPoints->new;
$sp->SetDimensions($image->GetOutput->GetDimensions);
$sp->SetExtent($image->GetOutput->GetExtent);
$sp->SetScalarType($image->GetOutput->GetScalarType);
$sp->SetNumberOfScalarComponents($image->GetOutput->GetNumberOfScalarComponents);
$sp->GetPointData->SetScalars($image->GetOutput->GetPointData->GetScalars);
$luminance = Graphics::VTK::ImageLuminance->new;
$luminance->SetInput($sp);
$tiff1 = Graphics::VTK::TIFFWriter->new;
$tiff1->SetInput($image->GetOutput);
$tiff1->SetFileName('tiff1.tif');
$tiff2 = Graphics::VTK::TIFFWriter->new;
$tiff2->SetInput($luminance->GetOutput);
$tiff2->SetFileName('tiff2.tif');
$bmp1 = Graphics::VTK::BMPWriter->new;
$bmp1->SetInput($image->GetOutput);
$bmp1->SetFileName('bmp1.bmp');
$bmp2 = Graphics::VTK::BMPWriter->new;
$bmp2->SetInput($luminance->GetOutput);
$bmp2->SetFileName('bmp2.bmp');
$tiff1->Write;
$tiff2->Write;
$bmp1->Write;
$bmp2->Write;
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($luminance->GetOutput);
$viewer->SetColorWindow(255);
$viewer->SetColorLevel(127.5);
$viewer->Render;
#make interface
do 'WindowLevelInterface.pl';
$windowToimage = Graphics::VTK::WindowToImageFilter->new;
$windowToimage->SetInput($viewer->GetImageWindow);
$pnmWriter = Graphics::VTK::PNMWriter->new;
$pnmWriter->SetInput($windowToimage->GetOutput);
$pnmWriter->SetFileName("TestAllWriters.tcl.ppm");
#  pnmWriter Write
