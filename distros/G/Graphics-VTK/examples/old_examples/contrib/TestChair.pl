#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetDataVOI(50,199,50,199,10,90);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
$ss = Graphics::VTK::ImageShiftScale->new;
$ss->SetOutputScalarTypeToUnsignedChar;
$ss->SetInput($reader->GetOutput);
$ss->SetScale(0.05);
$ss->SetShift(1000);
# Create outline
$chair = Graphics::VTK::ChairDisplay->new;
$chair->SetInput($ss->GetOutput);
$chair->SetXNotchSize(40);
$chair->SetYNotchSize(60);
$chair->SetZNotchSize(20);
$chairMapper = Graphics::VTK::PolyDataMapper->new;
$chairMapper->SetInput($chair->GetOutput);
$chairActor = Graphics::VTK::Actor->new;
$chairActor->SetMapper($chairMapper);
$atext = Graphics::VTK::Texture->new;
$atext->SetInput($chair->GetTextureOutput);
$atext->InterpolateOn;
$chairActor->SetTexture($atext);
$chairActor->GetProperty->SetAmbient(0.2);
# Okay now the graphics stuff
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$ren1->AddActor($chairActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->Render;
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
#vtkImageViewer viewer
#viewer SetInput [chair GetTextureOutput]
#viewer SetColorWindow 255
#viewer SetColorLevel 127.5
#viewer Render
$MW->withdraw;
#
sub loop
{
 my $i;
 for ($i = 1; $i < 40; $i += 1)
  {
   $chair->SetXNotchSize($i * 3);
   $chair->SetYNotchSize($i * 2);
   $chair->SetZNotchSize($i);
   $renWin->Render;
   #      viewer Render
  }
}
#
sub loop2
{
 my $i;
 $ss->UpdateWholeExtent;
 for ($i = 1; $i < 40; $i += 1)
  {
   $chair->SetXNotchSize($i * 3);
   $chair->SetYNotchSize($i * 2);
   $chair->SetZNotchSize($i);
   $renWin->Render;
   #      viewer Render
  }
}
#
sub timeit
{
 my $a;
 my $time;
 ($time->loop(1))[0] / 1000000.0;
 $a = "   Normal = [expr [lindex [time loop 1] 0]/1000000.0]
   Loaded into memory = [expr [lindex [time loop2 1] 0]/1000000.0]";
}
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
