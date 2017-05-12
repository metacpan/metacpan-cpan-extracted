#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;



use Graphics::VTK::Tk::vtkImageWindow;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetDataSpacing(1.0,1.0,2.0);
$reader->SetDataOrigin(0.0,0.0,-2.0);
$reader->SetFilePrefix("../../../vtkdata/fullHead/headsq");
$reader->SetDataMask(0x7fff);
#reader DebugOn
$reader->Update;
$reslice1 = Graphics::VTK::ImageReslice->new;
$reslice1->SetInput($reader->GetOutput);
$reslice1->SetInterpolationModeToCubic;
$reslice1->SetOutputSpacing(0.2,0.2,0.2);
$reslice1->SetOutputOrigin(100,150,51);
$reslice1->SetOutputExtent(0,255,0,255,0,0);
$reslice2 = Graphics::VTK::ImageReslice->new;
$reslice2->SetInput($reader->GetOutput);
$reslice2->SetInterpolationModeToLinear;
$reslice2->SetOutputSpacing(0.2,0.2,0.2);
$reslice2->SetOutputOrigin(100,150,51);
$reslice2->SetOutputExtent(0,255,0,255,0,0);
$reslice3 = Graphics::VTK::ImageReslice->new;
$reslice3->SetInput($reader->GetOutput);
$reslice3->SetInterpolationModeToNearestNeighbor;
$reslice3->SetOutputSpacing(0.2,0.2,0.2);
$reslice3->SetOutputOrigin(100,150,51);
$reslice3->SetOutputExtent(0,255,0,255,0,0);
$reslice4 = Graphics::VTK::ImageReslice->new;
$reslice4->SetInput($reader->GetOutput);
$reslice4->SetInterpolationModeToLinear;
$reslice4->SetOutputSpacing(1.0,1.0,1.0);
$reslice4->SetOutputOrigin(0,0,50);
$reslice4->SetOutputExtent(0,255,0,255,0,0);
$mapper1 = Graphics::VTK::ImageMapper->new;
$mapper1->SetInput($reslice1->GetOutput);
$mapper1->SetColorWindow(2000);
$mapper1->SetColorLevel(1000);
$mapper1->SetZSlice(0);
#  mapper1 DebugOn
$mapper2 = Graphics::VTK::ImageMapper->new;
$mapper2->SetInput($reslice2->GetOutput);
$mapper2->SetColorWindow(2000);
$mapper2->SetColorLevel(1000);
$mapper2->SetZSlice(0);
#  mapper2 DebugOn
$mapper3 = Graphics::VTK::ImageMapper->new;
$mapper3->SetInput($reslice3->GetOutput);
$mapper3->SetColorWindow(2000);
$mapper3->SetColorLevel(1000);
$mapper3->SetZSlice(0);
#  mapper3 DebugOn
$mapper4 = Graphics::VTK::ImageMapper->new;
$mapper4->SetInput($reslice4->GetOutput);
$mapper4->SetColorWindow(2000);
$mapper4->SetColorLevel(1000);
$mapper4->SetZSlice(0);
#  mapper4 DebugOn
$actor1 = Graphics::VTK::Actor2D->new;
$actor1->SetMapper($mapper1);
#  actor1 DebugOn
$actor2 = Graphics::VTK::Actor2D->new;
$actor2->SetMapper($mapper2);
#  actor2 DebugOn
$actor3 = Graphics::VTK::Actor2D->new;
$actor3->SetMapper($mapper3);
#  actor3 DebugOn
$actor4 = Graphics::VTK::Actor2D->new;
$actor4->SetMapper($mapper4);
#  actor4 DebugOn
$imager1 = Graphics::VTK::Imager->new;
$imager1->AddActor2D($actor1);
$imager1->SetViewport(0.5,0.0,1.0,0.5);
#  imager1 DebugOn
$imager2 = Graphics::VTK::Imager->new;
$imager2->AddActor2D($actor2);
$imager2->SetViewport(0.0,0.0,0.5,0.5);
#  imager2 DebugOn
$imager3 = Graphics::VTK::Imager->new;
$imager3->AddActor2D($actor3);
$imager3->SetViewport(0.5,0.5,1.0,1.0);
#  imager3 DebugOn
$imager4 = Graphics::VTK::Imager->new;
$imager4->AddActor2D($actor4);
$imager4->SetViewport(0.0,0.5,0.5,1.0);
#  imager4 DebugOn
$imgWin = Graphics::VTK::ImageWindow->new;
$imgWin->AddImager($imager1);
$imgWin->AddImager($imager2);
$imgWin->AddImager($imager3);
$imgWin->AddImager($imager4);
$imgWin->SetSize(512,512);
#  imgWin DebugOn
$imgWin->Render;
$MW->withdraw;
$w2i = Graphics::VTK::WindowToImageFilter->new;
$w2i->SetInput($imgWin);
$pnmWriter = Graphics::VTK::PNMWriter->new;
$pnmWriter->SetFileName('InterpolationModes.tcl.ppm');
$pnmWriter->SetInput($w2i->GetOutput);
#pnmWriter Write

Tk->MainLoop;
