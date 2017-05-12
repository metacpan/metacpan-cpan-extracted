#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is the tcl version of quadricCut.cxx
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
@solidTexture = (qw/255  255/);
@clearTexture = (qw/255  0/);
@edgeTexture = (qw/0  255/);
#
sub makeBooleanTexture
{
 my $caseNumber = shift;
 my $resolution = shift;
 my $thickness = shift;
 my $return;
 # Global Variables Declared for this function: solidTexture, clearTexture, edgeTexture
 $booleanTexture{$caseNumber} = Graphics::VTK::BooleanTexture->new;
 $booleanTexture{$caseNumber}->SetXSize($resolution);
 $booleanTexture{$caseNumber}->SetYSize($resolution);
 $booleanTexture{$caseNumber}->SetThickness($thickness);
 if ($caseNumber == 0)
  {
   $booleanTexture{$caseNumber}->SetInIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetInOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetOnOn(@solidTexture);
   $booleanTexture{$caseNumber}->SetOnIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetOnOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetInOn(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutOn(@solidTexture);
  }
 elsif ($caseNumber == 1)
  {
   $booleanTexture{$caseNumber}->SetInIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetInOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetOnOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnIn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetInOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOutOn(@solidTexture);
  }
 elsif ($caseNumber == 2)
  {
   $booleanTexture{$caseNumber}->SetInIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetInOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetOnOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnIn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetInOn(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutOn(@edgeTexture);
  }
 elsif ($caseNumber == 3)
  {
   $booleanTexture{$caseNumber}->SetInIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetInOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetOnOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetOnOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetInOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOutOn(@edgeTexture);
  }
 elsif ($caseNumber == 4)
  {
   $booleanTexture{$caseNumber}->SetInIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetInOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetOnOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetOnOut(@edgeTexture);
   $booleanTexture{$caseNumber}->SetInOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOutOn(@solidTexture);
  }
 elsif ($caseNumber == 5)
  {
   $booleanTexture{$caseNumber}->SetInIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetInOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetOnOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnIn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnOut(@edgeTexture);
   $booleanTexture{$caseNumber}->SetInOn(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutOn(@solidTexture);
  }
 elsif ($caseNumber == 6)
  {
   $booleanTexture{$caseNumber}->SetInIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetInOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetOnOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnIn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnOut(@edgeTexture);
   $booleanTexture{$caseNumber}->SetInOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOutOn(@edgeTexture);
  }
 elsif ($caseNumber == 7)
  {
   $booleanTexture{$caseNumber}->SetInIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetInOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetOnOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetOnOut(@edgeTexture);
   $booleanTexture{$caseNumber}->SetInOn(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutOn(@edgeTexture);
  }
 elsif ($caseNumber == 8)
  {
   $booleanTexture{$caseNumber}->SetInIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetInOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetOnOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetOnOut(@edgeTexture);
   $booleanTexture{$caseNumber}->SetInOn(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutOn(@edgeTexture);
  }
 elsif ($caseNumber == 9)
  {
   $booleanTexture{$caseNumber}->SetInIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetInOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetOnOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnIn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnOut(@edgeTexture);
   $booleanTexture{$caseNumber}->SetInOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOutOn(@edgeTexture);
  }
 elsif ($caseNumber == 10)
  {
   $booleanTexture{$caseNumber}->SetInIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetInOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetOnOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnIn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnOut(@edgeTexture);
   $booleanTexture{$caseNumber}->SetInOn(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutOn(@clearTexture);
  }
 elsif ($caseNumber == 11)
  {
   $booleanTexture{$caseNumber}->SetInIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetInOut(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetOnOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetOnOut(@edgeTexture);
   $booleanTexture{$caseNumber}->SetInOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOutOn(@clearTexture);
  }
 elsif ($caseNumber == 12)
  {
   $booleanTexture{$caseNumber}->SetInIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetInOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetOnOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetOnOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetInOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOutOn(@edgeTexture);
  }
 elsif ($caseNumber == 13)
  {
   $booleanTexture{$caseNumber}->SetInIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetInOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetOutOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetOnOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnIn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetInOn(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutOn(@edgeTexture);
  }
 elsif ($caseNumber == 14)
  {
   $booleanTexture{$caseNumber}->SetInIn(@solidTexture);
   $booleanTexture{$caseNumber}->SetInOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetOnOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnIn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOnOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetInOn(@edgeTexture);
   $booleanTexture{$caseNumber}->SetOutOn(@clearTexture);
  }
 elsif ($caseNumber == 15)
  {
   $booleanTexture{$caseNumber}->SetInIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetInOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetOnOn(@clearTexture);
   $booleanTexture{$caseNumber}->SetOnIn(@clearTexture);
   $booleanTexture{$caseNumber}->SetOnOut(@clearTexture);
   $booleanTexture{$caseNumber}->SetInOn(@clearTexture);
   $booleanTexture{$caseNumber}->SetOutOn(@clearTexture);
  }
 return $booleanTexture{$caseNumber};
}
$positions{0} = [qw/-4 4 0/];
$positions{1} = [qw/-2 4 0/];
$positions{2} = [qw/0 4 0/];
$positions{3} = [qw/2 4 0/];
$positions{4} = [qw/-4 2 0/];
$positions{5} = [qw/-2 2 0/];
$positions{6} = [qw/0 2 0/];
$positions{7} = [qw/2 2 0/];
$positions{8} = [qw/-4 0 0/];
$positions{9} = [qw/-2 0 0/];
$positions{10} = [qw/0 0 0/];
$positions{11} = [qw/2 0 0/];
$positions{12} = [qw/-4 -2 0/];
$positions{13} = [qw/-2 -2 0/];
$positions{14} = [qw/0 -2 0/];
$positions{15} = [qw/2 -2 0/];
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
# define two elliptical cylinders
$quadric1 = Graphics::VTK::Quadric->new;
$quadric1->SetCoefficients(1,2,0,0,0,0,0,0,0,'-.07');
$quadric2 = Graphics::VTK::Quadric->new;
$quadric2->SetCoefficients(2,1,0,0,0,0,0,0,0,'-.07');
# create a sphere for all to use
$aSphere = Graphics::VTK::SphereSource->new;
$aSphere->SetPhiResolution(50);
$aSphere->SetThetaResolution(50);
# create texture coordianates for all
$tcoords = Graphics::VTK::ImplicitTextureCoords->new;
$tcoords->SetInput($aSphere->GetOutput);
$tcoords->SetRFunction($quadric1);
$tcoords->SetSFunction($quadric2);
$aMapper = Graphics::VTK::DataSetMapper->new;
$aMapper->SetInput($tcoords->GetOutput);
# create a mapper, sphere and texture map for each case
for ($i = 0; $i < 16; $i += 1)
 {
  $aTexture{$i} = Graphics::VTK::Texture->new;
  $aTexture{$i}->SetInput(makeBooleanTexture($i,256,1)->GetOutput);
  $aTexture{$i}->InterpolateOff;
  $aTexture{$i}->RepeatOff;
  $anActor{$i} = Graphics::VTK::Actor->new;
  $anActor{$i}->SetMapper($aMapper);
  $anActor{$i}->SetTexture($aTexture{$i});
  $anActor{$i}->SetPosition(@{$positions{$i}});
  $anActor{$i}->SetScale(2.0,2.0,2.0);
  $ren1->AddActor($anActor{$i});
 }
$ren1->SetBackground(0.4392,0.5020,0.5647);
$ren1->GetActiveCamera->Zoom(1.4);
$renWin->SetSize(500,500);
# interact with data
$renWin->Render;
#renWin SetFileName "quadricCut.tcl.ppm" 
#renWin SaveImageAsPPM  
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
