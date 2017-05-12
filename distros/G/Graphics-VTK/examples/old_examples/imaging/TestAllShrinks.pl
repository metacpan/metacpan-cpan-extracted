#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;



use Graphics::VTK::Tk::vtkImageWindow;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
$prefix = "$VTK_DATA/fullHead/headsq";
$imgWin = Graphics::VTK::ImageWindow->new;
# Image pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix($prefix);
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataMask(0x7fff);
$factor = 6;
$ops = "Minimum Maximum Mean Median";
foreach $operator ($ops)
 {
  $shrink = Graphics::VTK::ImageShrink3D->new($,'operator');
  $shrink->_('operator',$On{$operator});
  $shrink->_('operator','SetShrinkFactors',$factor,$factor,$factor);
  $shrink->_('operator','SetInput',$reader->GetOutput);
  $mag = Graphics::VTK::ImageMagnify->new($,'operator');
  $mag->_('operator','SetMagnificationFactors',$factor,$factor,$factor);
  $mag->_('operator','InterpolateOff');
  $mag->_('operator','SetInput',$shrink->_('operator','GetOutput'));
  $mapper = Graphics::VTK::ImageMapper->new($,'operator');
  $mapper->_('operator','SetInput',$mag->_('operator','GetOutput'));
  $mapper->_('operator','SetColorWindow',2000);
  $mapper->_('operator','SetColorLevel',1000);
  $mapper->_('operator','SetZSlice',45);
  $actor = Graphics::VTK::Actor2D->new($,'operator');
  $actor->_('operator','SetMapper',"mapper$",'operator');
  $imager = Graphics::VTK::Imager->new($,'operator');
  $imager->_('operator','AddActor2D',"actor$",'operator');
  $imgWin->AddImager("imager$",'operator');
 }
#shrinkMinimum Update
#shrinkMaximum Update
#shrinkMean Update
#shrinkMedian Update
$imagerMinimum->SetViewport(0,0,'.5','.5');
$imagerMaximum->SetViewport(0,'.5','.5',1);
$imagerMean->SetViewport('.5',0,1,'.5');
$imagerMedian->SetViewport('.5','.5',1,1);
$imgWin->SetSize(512,512);
$imgWin->Render;
$imgWin->SetFileName('TestAllShrinks.tcl.ppm');
#imgWin SaveImageAsPPM
$MW->withdraw;

Tk->MainLoop;
