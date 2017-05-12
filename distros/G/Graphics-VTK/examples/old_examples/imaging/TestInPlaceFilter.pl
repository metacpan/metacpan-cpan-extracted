#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Derived from Cursor3D.  This script increases the coverage of the
# vtkImageInplaceFilter super class.
#source vtkImageInclude.tcl
# global values
$CURSOR_X = 20;
$CURSOR_Y = 20;
$CURSOR_Z = 20;
$IMAGE_MAG_X = 2;
$IMAGE_MAG_Y = 2;
$IMAGE_MAG_Z = 1;
# pipeline stuff
$reader = Graphics::VTK::SLCReader->new;
$reader->SetFileName("$VTK_DATA/poship.slc");
# make the image a little biger
$magnify1 = Graphics::VTK::ImageMagnify->new;
$magnify1->SetInput($reader->GetOutput);
$magnify1->SetMagnificationFactors($IMAGE_MAG_X,$IMAGE_MAG_Y,$IMAGE_MAG_Z);
$magnify1->ReleaseDataFlagOn;
$magnify2 = Graphics::VTK::ImageMagnify->new;
$magnify2->SetInput($reader->GetOutput);
$magnify2->SetMagnificationFactors($IMAGE_MAG_X,$IMAGE_MAG_Y,$IMAGE_MAG_Z);
$magnify2->ReleaseDataFlagOn;
# a filter that does in place processing (magnify ReleaseDataFlagOn)
$cursor = Graphics::VTK::ImageCursor3D->new;
$cursor->SetInput($magnify1->GetOutput);
$cursor->SetCursorPosition($CURSOR_X * $IMAGE_MAG_X,$CURSOR_Y * $IMAGE_MAG_Y,$CURSOR_Z * $IMAGE_MAG_Z);
$cursor->SetCursorValue(255);
$cursor->SetCursorRadius(50 * $IMAGE_MAG_X);
# stream to increase coverage of in place filter.
# put thge two together in one image
$append = Graphics::VTK::ImageAppend->new;
$SetAppendAxis = $SetAppendAxis . 0;
$AddInput = $AddInput . $magnify2->GetOutput;
$AddInput = $AddInput . $cursor->GetOutput;
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($append->GetOutput);
$viewer->SetZSlice($CURSOR_Z * $IMAGE_MAG_Z);
$viewer->SetColorWindow(200);
$viewer->SetColorLevel(80);
#viewer DebugOn
$viewer->Render;
$viewer->SetPosition(50,50);
#make interface
do 'WindowLevelInterface.pl';
