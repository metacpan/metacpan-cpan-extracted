#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

## Create a little app for loading and viewing polygonal files
##
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
use Graphics::VTK::Tk::vtkInteractor;
# Create gui
$MW->title("vtk Polygonal Data Viewer");
$MW->{'.mbar'} = $MW->Frame('-relief','raised','-bd',2);
$MW->{'.mbar'}->pack('-side','top','-fill','x');
$MW->{'.mbar.file'} = $MW->{'.mbar'}->Menubutton('-text','File');
$MW->{'.mbar.view'} = $MW->{'.mbar'}->Menubutton('-text','View');
$MW->{'.mbar.help'} = $MW->{'.mbar'}->Menubutton('-text','Help');
foreach $_ (($MW->{'.mbar.file'},$MW->{'.mbar.view'}))
 {
  $_->pack('-side','left');
 }
$MW->{'.mbar.help'}->pack('-side','right');
# menu .mbar.file.menu
$MW->{'.mbar.file'}->command('-label','Open','-command',
 sub
  {
   OpenFile();
  }
);
$MW->{'.mbar.file'}->command('-label','Exit','-command',
 sub
  {
   exit();
  }
);
$view = 'Left';
# menu .mbar.view.menu
$MW->{'.mbar.view'}->radiobutton('-label','Front','-value','Front','-command',
 sub
  {
   UpdateView(1,0,0,0,1,0);
  }
,'-variable',\$view);
$MW->{'.mbar.view'}->radiobutton('-label','Back','-value','Back','-command',
 sub
  {
   UpdateView(-1,0,0,0,1,0);
  }
,'-variable',\$view);
$MW->{'.mbar.view'}->radiobutton('-label','Left','-value','Left','-command',
 sub
  {
   UpdateView(0,0,1,0,1,0);
  }
,'-variable',\$view);
$MW->{'.mbar.view'}->radiobutton('-label','Right','-value','Right','-command',
 sub
  {
   UpdateView(0,0,-1,0,1,0);
  }
,'-variable',\$view);
$MW->{'.mbar.view'}->radiobutton('-label','Top','-value','Top','-command',
 sub
  {
   UpdateView(0,1,0,0,0,1);
  }
,'-variable',\$view);
$MW->{'.mbar.view'}->radiobutton('-label','Bottom','-value','Bottom','-command',
 sub
  {
   UpdateView(0,-1,0,0,0,1);
  }
,'-variable',\$view);
$MW->{'.mbar.view'}->radiobutton('-label','Isometric','-value','Isometric','-command',
 sub
  {
   UpdateView(1,1,1,0,1,0);
  }
,'-variable',\$view);
# menu .mbar.help.menu
$MW->{'.mbar.help'}->command('-label','Buy a Kitware support contract!');
$MW->{'.window'} = $MW->vtkInteractor('-width',300,'-height',300);
#    BindTkRenderWidget .window
$MW->{'.window'}->pack('-side','top','-anchor','nw','-padx',3,'-pady',3,'-fill','both','-expand',1);
# Procedure to set particular views
#
sub UpdateView
{
 my $x = shift;
 my $y = shift;
 my $z = shift;
 my $vx = shift;
 my $vy = shift;
 my $vz = shift;
 my $Render;
 # Global Variables Declared for this function: renWin
 $camera = $ren->GetActiveCamera;
 $camera->SetViewPlaneNormal($x,$y,$z);
 $camera->SetViewUp($vx,$vy,$vz);
 $ren->ResetCamera;
 $MW->{'.window'}->Render;
}
# Procedure opens file and resets view
#
sub OpenFile
{
 my $filename;
 my $return;
 my $tk_getOpenFile;
 my $types;
 # Global Variables Declared for this function: renWin, reader
 $types = [['BYU','.g'],['Stereo-Lithography','.stl'],['Visualization Toolkit (polygonal)','.vtk'],['All Files ','*']];
 $filename = $MW->getOpenFile(-filetypes => $types);
 if ($filename ne "")
  {
   $ren->RemoveActor($bannerActor);
   $ren->RemoveActor($actor);
   if ($filename =~ /.*?\.g/)
    {
     $reader = $byu;
     $byu->SetGeometryFileName($filename);
    }
   elsif ($filename =~ /.*?\.stl/)
    {
     $reader = $stl;
     $stl->SetFileName($filename);
    }
   elsif ($filename =~ /.*?\.vtk/)
    {
     $reader = $vtk;
     $vtk->SetFileName($filename);
    }
   else
    {
     print("Can't read this file");
     return;
    }
   $mapper->SetInput($reader->GetOutput);
   $reader->Update;
   if ($reader->GetOutput->GetNumberOfCells <= 0)
    {
     $ren->AddActor($bannerActor);
    }
   else
    {
     $ren->AddActor($actor);
    }
   $ren->ResetCamera;
   $renWin->Render;
  }
}
# Create pipeline
$stl = Graphics::VTK::STLReader->new;
$reader = $stl;
$byu = Graphics::VTK::BYUReader->new;
$vtk = Graphics::VTK::PolyDataReader->new;
$mapper = Graphics::VTK::PolyDataMapper->new;
$actor = Graphics::VTK::Actor->new;
$actor->SetMapper($mapper);
$banner = Graphics::VTK::VectorText->new;
$banner->SetText("         vtk\nPolygonal Data\n      Viewer");
$bannerMapper = Graphics::VTK::PolyDataMapper->new;
$bannerMapper->SetInput($banner->GetOutput);
$bannerActor = Graphics::VTK::Actor->new;
$bannerActor->SetMapper($bannerMapper);
$renWin = $MW->{'.window'}->GetRenderWindow;
$ren = Graphics::VTK::Renderer->new;
$renWin->AddRenderer($ren);
$ren->AddActor($bannerActor);
$ren->GetActiveCamera->Zoom(1.25);

Tk->MainLoop;
