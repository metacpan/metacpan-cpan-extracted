#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;



use Graphics::VTK::Tk::vtkImageWindow;

# append multiple displaced spheres into an RGB image.
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Image pipeline
$imgWin = Graphics::VTK::ImageWindow->new;
$sphere1 = Graphics::VTK::ImageEllipsoidSource->new;
$sphere1->SetCenter(40,20,0);
$sphere1->SetRadius(30,30,0);
$sphere1->SetInValue('.75');
$sphere1->SetOutValue('.3');
$sphere1->SetOutputScalarTypeToFloat;
$sphere2 = Graphics::VTK::ImageEllipsoidSource->new;
$sphere2->SetCenter(60,30,0);
$sphere2->SetRadius(20,20,20);
$sphere2->SetInValue('.2');
$sphere2->SetOutValue('.5');
$sphere2->SetOutputScalarTypeToFloat;
$mathematics = " Add  Subtract  Multiply  Divide  Invert  Sin  Cos  Exp  Log  AbsoluteValue  Square  SquareRoot  Min  Max  ATAN  ATAN2  MultiplyByK  AddConstant";
foreach $operator ($mathematics)
 {
  $mathematic = Graphics::VTK::ImageMathematics->new($,'operator');
  $mathematic->_('operator','SetInput1',$sphere1->GetOutput);
  $mathematic->_('operator','SetInput2',$sphere2->GetOutput);
  $mathematic->_('operator',"SetOperationTo$",'operator');
  $mathematic->_('operator','SetConstantK','.21');
  $mathematic->_('operator','SetConstantC','.1');
  $mapper = Graphics::VTK::ImageMapper->new($,'operator');
  $mapper->_('operator','SetInput',$mathematic->_('operator','GetOutput'));
  $mapper->_('operator','SetColorWindow',2.0);
  $mapper->_('operator','SetColorLevel','.75');
  $actor = Graphics::VTK::Actor2D->new($,'operator');
  $actor->_('operator','SetMapper',"mapper$",'operator');
  $imager = Graphics::VTK::Imager->new($,'operator');
  $imager->_('operator','AddActor2D',"actor$",'operator');
  $imgWin->AddImager("imager$",'operator');
 }
$column = 1;
$row = 1;
$deltaX = 1.0 / 6.0;
$deltaY = 1.0 / 3.0;
foreach $operator ($mathematics)
 {
  $imager->_('operator','SetViewport',($column - 1) * $deltaX,($row - 1) * $deltaY,$column * $deltaX,$row * $deltaY);
  $column += 1;
  if ($column > 6)
   {
    $column = 1;
    $row += 1;
   }
 }
$imgWin->SetSize(600,300);
$imgWin->Render;
$imgWin->SetFileName('TestAllMathematics.tcl.ppm');
#imgWin SaveImageAsPPM
$MW->withdraw;

Tk->MainLoop;
