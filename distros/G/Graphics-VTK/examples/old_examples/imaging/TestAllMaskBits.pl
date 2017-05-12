#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;



use Graphics::VTK::Tk::vtkImageWindow;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# This script calculates the luminanace of an image
$imgWin = Graphics::VTK::ImageWindow->new;
# Image pipeline
$image = Graphics::VTK::BMPReader->new;
$image->SetFileName("$VTK_DATA/beach.bmp");
$shrink = Graphics::VTK::ImageShrink3D->new;
$shrink->SetInput($image->GetOutput);
$shrink->SetShrinkFactors(4,4,1);
$operators = " ByPass  And  Nand  Xor \ 
Or \ 
Nor";
foreach $operator ($operators)
 {
  if ($operator ne "ByPass")
   {
    $operator = Graphics::VTK::ImageMaskBits->new($,'operator');
    $operator->_('operator','SetInput',$shrink->GetOutput);
    $operator->_('operator',"SetOperationTo$",'operator');
    $operator->_('operator','SetMasks',255,255,0);
   }
  $mapper = Graphics::VTK::ImageMapper->new($,'operator');
  if ($operator ne "ByPass")
   {
    $mapper->_('operator','SetInput',$operator->_('operator','GetOutput'));
   }
  else
   {
    $mapper->_('operator','SetInput',$shrink->GetOutput);
   }
  $mapper->_('operator','SetColorWindow',255);
  $mapper->_('operator','SetColorLevel',127.5);
  $actor = Graphics::VTK::Actor2D->new($,'operator');
  $actor->_('operator','SetMapper',"mapper$",'operator');
  $imager = Graphics::VTK::Imager->new($,'operator');
  $imager->_('operator','AddActor2D',"actor$",'operator');
  $imgWin->AddImager("imager$",'operator');
 }
$column = 1;
$row = 1;
$deltaX = 1.0 / 3.0;
$deltaY = 1.0 / 2.0;
foreach $operator ($operators)
 {
  $imager->_('operator','SetViewport',($column - 1) * $deltaX,($row - 1) * $deltaY,$column * $deltaX,$row * $deltaY);
  $column += 1;
  if ($column > 3)
   {
    $column = 1;
    $row += 1;
   }
 }
$imgWin->SetSize(384,256);
$imgWin->Render;
$imgWin->SetFileName('TestAllMaskBits.tcl.ppm');
#imgWin SaveImageAsPPM
$MW->withdraw;

Tk->MainLoop;
