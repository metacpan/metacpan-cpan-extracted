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
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
#reader DebugOn
$reader->Update;
$magnify = Graphics::VTK::ImageMagnify->new;
$magnify->SetInput($reader->GetOutput);
$magnify->SetMagnificationFactors(2,2,1);
#magnify InterpolateOn
$mapper1 = Graphics::VTK::ImageMapper->new;
$mapper1->SetInput($magnify->GetOutput);
$mapper1->SetColorWindow(2000);
$mapper1->SetColorLevel(1000);
$mapper1->SetZSlice(20);
#  mapper1 DebugOn
$mapper2 = Graphics::VTK::ImageMapper->new;
$mapper2->SetInput($reader->GetOutput);
$mapper2->SetColorWindow(2000);
$mapper2->SetColorLevel(1000);
$mapper2->SetZSlice(50);
#  mapper2 DebugOn
$mapper3 = Graphics::VTK::ImageMapper->new;
$mapper3->SetInput($reader->GetOutput);
$mapper3->SetColorWindow(2000);
$mapper3->SetColorLevel(1000);
$mapper3->SetZSlice(70);
#  mapper3 DebugOn
$mapper4 = Graphics::VTK::ImageMapper->new;
$mapper4->SetInput($reader->GetOutput);
$mapper4->SetColorWindow(2000);
$mapper4->SetColorLevel(1000);
$mapper4->SetZSlice(90);
#  mapper4 DebugOn
$mapper5 = Graphics::VTK::ImageMapper->new;
$mapper5->SetInput($reader->GetOutput);
$mapper5->SetColorWindow(2000);
$mapper5->SetColorLevel(1000);
$mapper5->SetZSlice(90);
#  mapper5 DebugOn
$mapper6 = Graphics::VTK::ImageMapper->new;
$mapper6->SetInput($reader->GetOutput);
$mapper6->SetColorWindow(2000);
$mapper6->SetColorLevel(1000);
$mapper6->SetZSlice(90);
#  mapper6 DebugOn
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
$actor5 = Graphics::VTK::Actor2D->new;
$actor5->SetMapper($mapper5);
#  actor5 DebugOn
$actor6 = Graphics::VTK::Actor2D->new;
$actor6->SetMapper($mapper6);
#  actor6 DebugOn
$imager1 = Graphics::VTK::Imager->new;
$imager1->AddActor2D($actor1);
#  imager1 SetViewport 0.0 0.66 0.33 1.0 
$imager1->SetViewport(0.0,0.33,0.66,1.0);
#  imager1 DebugOn
$imager2 = Graphics::VTK::Imager->new;
$imager2->AddActor2D($actor2);
#  imager2 SetViewport 0.0 0.33 0.0 0.33 
$imager2->SetViewport(0.0,0.0,0.33,0.33);
#  imager2 DebugOn
$imager3 = Graphics::VTK::Imager->new;
$imager3->AddActor2D($actor3);
#  imager3 SetViewport 0.33 0.66 0.0 0.33 
$imager3->SetViewport(0.33,0.0,0.66,0.33);
#  imager3 DebugOn
$imager4 = Graphics::VTK::Imager->new;
$imager4->AddActor2D($actor4);
#  imager4 SetViewport 0.66 1.0 0.0 0.33 
$imager4->SetViewport(0.66,0.0,1.0,0.33);
#  imager4 DebugOn
$imager5 = Graphics::VTK::Imager->new;
$imager5->AddActor2D($actor5);
#  imager5 SetViewport 0.66 1.0 0.33 0.66 
$imager5->SetViewport(0.66,0.33,1.0,0.66);
#  imager5 DebugOn
$imager6 = Graphics::VTK::Imager->new;
$imager6->AddActor2D($actor6);
#  imager6 SetViewport 0.66 1.0 0.66 1.0
$imager6->SetViewport(0.66,0.66,1.0,1.0);
#  imager6 DebugOn
$imgWin = Graphics::VTK::ImageWindow->new;
$imgWin->AddImager($imager1);
$imgWin->AddImager($imager2);
$imgWin->AddImager($imager3);
$imgWin->AddImager($imager4);
$imgWin->AddImager($imager5);
$imgWin->AddImager($imager6);
$imgWin->SetSize(512,512);
#  imgWin DebugOn
$imgWin->Render;
$MW->withdraw;
# time the window level operation
$i = 0;
#
sub timeit
{
 my $time;
 # Global Variables Declared for this function: i
 print(1000000.0 / ($time->mapper1_SetColorLevel__i_______________________________________imgWin_Render_______________________________________incr_i(100))[0]);
}
#
sub cine
{
 my $i;
 for ($i = 0; $i < 89; $i += 1)
  {
   $mapper1->SetZSlice($i);
   $mapper2->SetZSlice($i + 1);
   $mapper3->SetZSlice($i + 2);
   $mapper4->SetZSlice($i + 3);
   $mapper5->SetZSlice($i + 4);
   $mapper6->SetZSlice($i + 5);
   $imgWin->Render;
  }
}
#
sub cine_up
{
 my $i;
 for ($i = 30; $i < 90; $i += 1)
  {
   $mapper1->SetZSlice($i);
   $imgWin->Render;
  }
}
$w2i = Graphics::VTK::WindowToImageFilter->new;
$w2i->SetInput($imgWin);
$bmp = Graphics::VTK::BMPWriter->new;
$bmp->SetFileName('viewport.bmp');
$bmp->SetInput($w2i->GetOutput);
#bmp Write

Tk->MainLoop;
