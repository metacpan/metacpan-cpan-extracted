#!/usr/local/bin/perl -w
#
use Graphics::VTK;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
$source->______imaging_examplesTcl_vtkImageInclude_tcl;
# Image pipeline
$reader = Graphics::VTK::ImageBlockReader->new;
$reader->SetFilePattern("tmp/blocks_%d_%d_%d.vtk");
$reader->SetDivisions(4,4,4);
$reader->SetOverlap(3);
$reader->SetWholeExtent(0,255,0,255,1,33);
$reader->SetNumberOfScalarComponents(1);
$reader->SetScalarType($VTK_UNSIGNED_SHORT);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($reader->GetOutput);
$viewer->SetZSlice(14);
$viewer->SetColorWindow(2000);
$viewer->SetColorLevel(1000);
$viewer->SetPosition(50,50);
$viewer->Render;
#make interface
$source->______imaging_examplesTcl_WindowLevelInterface_tcl;
