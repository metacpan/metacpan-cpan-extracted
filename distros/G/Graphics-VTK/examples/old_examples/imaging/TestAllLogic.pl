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
$logics = "And Or Xor Nand Nor Not";
$types = "Float Double UnsignedInt UnsignedLong UnsignedShort UnsignedChar";
$i = 0;
foreach $operator ($logics)
 {
  $ScalarType = $types[$i];
  $sphere1 = Graphics::VTK::ImageEllipsoidSource->new($,'operator');
  $sphere1->_('operator','SetCenter',95,100,0);
  $sphere1->_('operator','SetRadius',70,70,70);
  $sphere1->_('operator',"SetOutputScalarTypeTo$",'ScalarType');
  $sphere2 = Graphics::VTK::ImageEllipsoidSource->new($,'operator');
  $sphere2->_('operator','SetCenter',161,100,0);
  $sphere2->_('operator','SetRadius',70,70,70);
  $sphere2->_('operator',"SetOutputScalarTypeTo$",'ScalarType');
  $logic = Graphics::VTK::ImageLogic->new($,'operator');
  $logic->_('operator','SetInput1',$sphere1->_('operator','GetOutput'));
  $logic->_('operator','SetInput2',$sphere2->_('operator','GetOutput'));
  $logic->_('operator','SetOutputTrueValue',150);
  $logic->_('operator',"SetOperationTo$",'operator');
  $mapper = Graphics::VTK::ImageMapper->new($,'operator');
  $mapper->_('operator','SetInput',$logic->_('operator','GetOutput'));
  $mapper->_('operator','SetColorWindow',255);
  $mapper->_('operator','SetColorLevel',127.5);
  $actor = Graphics::VTK::Actor2D->new($,'operator');
  $actor->_('operator','SetMapper',"mapper$",'operator');
  $imager = Graphics::VTK::Imager->new($,'operator');
  $imager->_('operator','AddActor2D',"actor$",'operator');
  $imgWin->AddImager("imager$",'operator');
  $i += 1;
 }
$imagerAnd->SetViewport(0,'.5','.33',1);
$imagerOr->SetViewport('.33','.5','.66',1);
$imagerXor->SetViewport('.66','.5',1,1);
$imagerNand->SetViewport(0,0,'.33','.5');
$imagerNor->SetViewport('.33',0,'.66','.5');
$imagerNot->SetViewport('.66',0,1,'.5');
$imgWin->SetSize(768,512);
$imgWin->Render;
$imgWin->SetFileName('TestAllLogic.tcl.ppm');
#imgWin SaveImageAsPPM
$MW->withdraw;

Tk->MainLoop;
