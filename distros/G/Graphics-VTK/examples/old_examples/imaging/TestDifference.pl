#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# append multiple displaced spheres into an RGB image.
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#source vtkImageInclude.tcl
use Graphics::VTK::Tk::vtkImageViewer;
# Image pipeline
$canvas1 = Graphics::VTK::ImageCanvasSource2D->new;
$canvas1->SetNumberOfScalarComponents(3);
$canvas1->SetScalarType($Graphics::VTK::UNSIGNED_CHAR);
$canvas1->SetExtent(0,511,0,511,0,0);
$canvas1->SetDrawColor(100,100,0);
$canvas1->FillBox(0,511,0,511);
$canvas1->SetDrawColor(200,0,200);
$canvas1->FillBox(32,511,100,500);
$canvas1->SetDrawColor(100,0,0);
$canvas1->FillTube(550,20,30,400,5);
$canvas2 = Graphics::VTK::ImageCanvasSource2D->new;
$canvas2->SetNumberOfScalarComponents(3);
$canvas2->SetScalarType($Graphics::VTK::UNSIGNED_CHAR);
$canvas2->SetExtent(0,511,0,511,0,0);
$canvas2->SetDrawColor(100,100,0);
$canvas2->FillBox(0,511,0,511);
$canvas2->SetDrawColor(200,0,200);
$canvas2->FillBox(32,511,100,500);
$canvas2->SetDrawColor(100,0,0);
#canvas2 FillTube 550 20 30 400 5
$diff = Graphics::VTK::ImageDifference->new;
$diff->SetInput($canvas1->GetOutput);
$diff->SetImage($canvas2->GetOutput);
$viewer = Graphics::VTK::ImageViewer->new;
$viewer->SetInput($diff->GetOutput);
$viewer->SetColorWindow(25);
$viewer->SetColorLevel(1);
# make interface
# Create the GUI: two renderer widgets and a quit button
$MW->withdraw;
$MW->{'.top'} = $MW->Toplevel;
$MW->{'.top.f1'} = $MW->{'.top'}->Frame;
$MW->{'.top.f1.r1'} = $MW->{'.top.f1'}->vtkImageViewer('-width',512,'-height',512,'-iv',$viewer);
#    BindTkRenderWidget .top.f1.r1
$MW->{'.top.btn'} = $MW->{'.top'}->Button('-text','Quit','-command',
 sub
  {
   exit();
  }
);
$MW->{'.top.f1.r1'}->pack('-side','left','-padx',3,'-pady',3,'-fill','both','-expand','t');
$MW->{'.top.f1'}->pack('-fill','both','-expand','t');
$MW->{'.top.btn'}->pack('-fill','x');
#BindTkImageViewer .top.f1.r1 

Tk->MainLoop;
