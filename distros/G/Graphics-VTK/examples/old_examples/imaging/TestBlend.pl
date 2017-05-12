#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#source vtkImageInclude.tcl
# do alpha-blending of two images
$reader1 = Graphics::VTK::PNMReader->new;
$reader1->SetFileName("$VTK_DATA/masonry.ppm");
$reader2 = Graphics::VTK::PNMReader->new;
$reader2->SetFileName("$VTK_DATA/B.pgm");
$table = Graphics::VTK::LookupTable->new;
$table->SetTableRange(0,127);
$table->SetValueRange(0.0,1.0);
$table->SetSaturationRange(0.0,0.0);
$table->SetHueRange(0.0,0.0);
$table->SetAlphaRange(0.9,0.0);
$table->Build;
$rgba = Graphics::VTK::ImageMapToColors->new;
$rgba->SetInput($reader2->GetOutput);
$rgba->SetLookupTable($table);
$translate = Graphics::VTK::ImageTranslateExtent->new;
$translate->SetInput($rgba->GetOutput);
$translate->SetTranslation(60,60,0);
$blend = Graphics::VTK::ImageBlend->new;
$blend->SetInput(0,$reader1->GetOutput);
$blend->SetInput(1,$translate->GetOutput);
#blend SetOpacity 1 0.5 
# set the window/level to 255.0/127.5 to view full range
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($blend->GetOutput);
$viewer->SetColorWindow(255.0);
$viewer->SetColorLevel(127.5);
$viewer->SetZSlice(0);
$viewer->Render;
$opacity = 1;
#
sub SetOpacity
{
 my $opacity = shift;
 $blend->SetOpacity(1,$opacity);
 $viewer->Render;
}
SetOpacity(1);
#make interface
$windowToimage = Graphics::VTK::WindowToImageFilter->new;
$windowToimage->SetInput($viewer->GetImageWindow);
$pnmWriter = Graphics::VTK::PNMWriter->new;
$pnmWriter->SetInput($windowToimage->GetOutput);
$pnmWriter->SetFileName("TestBlend.tcl.ppm");
#  pnmWriter Write
$source->______imaging_examplesTcl_WindowLevelInterface_tcl;
# only show ui if not testing
if (defined('rtExMath') ne "rtExMath")
 {
  $MW->{'.wl.f3'} = $MW->{'.wl'}->Frame;
  $MW->{'.wl.f3.opacityLabel'} = $MW->{'.wl.f3'}->Label('-text',"Opacity");
  $MW->{'.wl.f3.opacity'} = $MW->{'.wl.f3'}->Scale('-from',0.0,'-resolution','.01','-to',1.0,'-variable',\$opacity,'-command',
   sub
    {
     SetOpacity();
    }
  ,'-orient','horizontal');
  $MW->{'.wl.f3'}->pack('-side','top');
  foreach $_ (($MW->{'.wl.f3.opacityLabel'},$MW->{'.wl.f3.opacity'}))
   {
    $_->pack('-side','left');
   }
 }

Tk->MainLoop;
