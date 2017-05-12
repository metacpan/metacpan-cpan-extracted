#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Graphics::VTK::Tk::vtkImageWindow;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
$source->ViewerApp_tcl;
$imgWin = Graphics::VTK::ImageWindow->new;
$BypassOff->gradient;
$BypassOff->magnitude;
$viewer->Render;
$ResetTkImageViewer->_top_f1_v1;
