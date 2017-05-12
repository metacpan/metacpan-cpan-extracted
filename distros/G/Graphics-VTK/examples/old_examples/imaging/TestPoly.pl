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
$vtext->SetText("VTK Baby!");
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
$textActor->GetProperty->SetColor(0.7,0.7,1.0);
$textActor->GetPositionCoordinate->SetReferenceCoordinate($coord);
$textActor->GetPositionCoordinate->SetCoordinateSystemToViewport;
$textActor->GetPositionCoordinate->SetValue(-100,-20);
$imager1 = Graphics::VTK::Imager->new;
$imager1->AddActor2D($textActor);
$imgWin = Graphics::VTK::ImageWindow->new;
$imgWin->AddImager($imager1);
$imgWin->Render;
$MW->withdraw;

Tk->MainLoop;
