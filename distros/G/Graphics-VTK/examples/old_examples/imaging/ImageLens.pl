#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# the start of a mini application that will let the user select
# circular region of an image to process specifically.
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#source vtkImageInclude.tcl
#source $VTK_TCL/WidgetObject.tcl
# This script uses a vtkTkRenderWidget to create a
# Tk widget that is associated with a vtkRenderWindow.
#source TkInteractor.tcl
$reader = Graphics::VTK::PNMReader->new;
$reader->ReleaseDataFlagOff;
$reader->SetFileName("$VTK_DATA/earth.ppm");
$cast = Graphics::VTK::ImageCast->new;
$cast->SetInput($reader->GetOutput);
$cast->SetOutputScalarTypeToFloat;
$filter = Graphics::VTK::ImageGradientMagnitude->new;
$filter->SetInput($cast->GetOutput);
$shiftScale = Graphics::VTK::ImageShiftScale->new;
$shiftScale->SetInput($filter->GetOutput);
$shiftScale->SetShift(64);
$shiftScale->SetScale(2.0);
$mask = Graphics::VTK::ImageEllipsoidSource->new;
$mask->SetRadius(40,40,30000);
$mask->SetCenter(100,100,0);
# set the correct size
$cast->UpdateInformation;
$mask->SetWholeExtent(0,511,0,255,0,0);
$clip1 = Graphics::VTK::ImageMask->new;
$clip1->SetImageInput($cast->GetOutput);
$clip1->SetMaskInput($mask->GetOutput);
$clip1->SetMaskedOutputValue(0.0);
$clip1->NotMaskOn;
$clip2 = Graphics::VTK::ImageMask->new;
$clip2->SetImageInput($shiftScale->GetOutput);
$clip2->SetMaskInput($mask->GetOutput);
$clip2->SetMaskedOutputValue(0.0);
$clip2->NotMaskOff;
$add = Graphics::VTK::ImageMathematics->new;
$add->SetOperationToAdd;
$add->SetInput1($clip1->GetOutput);
$add->SetInput2($clip2->GetOutput);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($add->GetOutput);
$viewer->SetColorWindow(256);
$viewer->SetColorLevel(127.5);
#
sub moveLens
{
 my $x = shift;
 my $y = shift;
 #flip Y axis
 $y = 255 - $y;
 $mask->SetCenter($x,$y,0);
 $viewer->Render;
}
# Create the GUI: two renderer widgets and a quit button
$MW->withdraw;
$MW->{'.top'} = $MW->Toplevel;
$MW->{'.top.f1'} = $MW->{'.top'}->Frame;
$MW->{'.top.f1.r1'} = $MW->{'.top.f1'}->vtkImageViewer('-width',512,'-height',256,'-iv',$viewer);
$MW->{'.top.f1.r1'}->bind('<Button-1>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   moveLens($Ev->x,$Ev->y);
  }
);
$MW->{'.top.f1.r1'}->bind('<B1-Motion>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   moveLens($Ev->x,$Ev->y);
  }
);
$MW->{'.top.f1.r1'}->bind('<Expose>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   Expose($W);
  }
);
# a litle more complex than just "bind $widget <Expose> {%W Render}"
# we have to handle all pending expose events otherwise they que up.
#
sub Expose
{
 my $widget = shift;
 my $return;
 return if ($widget->{'InExpose'} == 1);
 $widget->{'InExpose'} = 1;
 $MW->update;
 $widget->Render;
 $widget->{'InExpose'} = 0;
}
$MW->{'.top.btn'} = $MW->{'.top'}->Button('-text','Quit','-command',
 sub
  {
   exit();
  }
);
$MW->{'.top.f1.r1'}->pack('-side','left','-padx',3,'-pady',3,'-fill','both','-expand','t');
$MW->{'.top.f1'}->pack('-fill','both','-expand','t');
$MW->{'.top.btn'}->pack('-fill','x');

Tk->MainLoop;
