#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;



use Graphics::VTK::Tk::vtkImageWindow;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$mapper2 = Graphics::VTK::ImageMapper->new;
$mapper2->SetInput($reader->GetOutput);
$mapper2->SetColorWindow(2000);
$mapper2->SetColorLevel(1000);
$mapper2->SetZSlice(50);
$actor2 = Graphics::VTK::Actor2D->new;
$actor2->SetMapper($mapper2);
$vtext = Graphics::VTK::VectorText->new;
$vtext->SetText("Imagine!");
$trans = Graphics::VTK::Transform->new;
$trans->Scale(25,25,25);
$tpd = Graphics::VTK::TransformPolyDataFilter->new;
$tpd->SetTransform($trans);
$tpd->SetInput($vtext->GetOutput);
$textMapper = Graphics::VTK::PolyDataMapper2D->new;
$textMapper->SetInput($tpd->GetOutput);
$coord = Graphics::VTK::Coordinate->new;
$coord->SetCoordinateSystemToNormalizedViewport;
$coord->SetValue(0.5,0.5);
$textActor = Graphics::VTK::Actor2D->new;
$textActor->SetMapper($textMapper);
$textActor->GetProperty->SetColor(0.7,1.0,1.0);
$textActor->GetPositionCoordinate->SetReferenceCoordinate($coord);
$textActor->GetPositionCoordinate->SetCoordinateSystemToViewport;
$textActor->GetPositionCoordinate->SetValue(-80,-20);
$imager1 = Graphics::VTK::Imager->new;
$imager1->AddActor2D($textActor);
$imgWin = Graphics::VTK::ImageWindow->new;
$imgWin->AddImager($imager1);
$MW->withdraw;
$MW->{'.top'} = $MW->Toplevel;
$MW->{'.top.f1'} = $MW->{'.top'}->Frame;
$MW->{'.top.f1.r1'} = $MW->{'.top.f1'}->vtkImageWindow('-iw',$imgWin,'-width',256,'-height',256);
$MW->{'.top.btn'} = $MW->{'.top'}->Button('-text','Quit','-command',
 sub
  {
   exit();
  }
);
$MW->{'.top.f1.r1'}->pack('-side','left','-padx',3,'-pady',3,'-fill','both','-expand','t');
$MW->{'.top.f1'}->pack('-fill','both','-expand','t');
$MW->{'.top.btn'}->pack('-fill','x');
$imager1->SetBackground(0.1,0.0,0.6);
$MW->{'.top.f1.r1'}->bind('<Expose>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   $MW->{'.top.f1.r1'}->Render;
  }
);
$MW->update;
$imgWin->SetFileName("junk.ppm");
$imgWin->SaveImageAsPPM;
system('rm','junk.ppm');

Tk->MainLoop;
