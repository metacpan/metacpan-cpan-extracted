#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# Load the vtk tcl library
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# Source the interactor that we will use for the TkRenderWidget
use Graphics::VTK::Tk::vtkInteractor;
# Set some variables to default values
$low_res = 4;
$med_res = 12;
$high_res = 24;
# Remove the default toplevel
$MW->withdraw;
# Create the toplevel window
$MW->{'.top'} = $MW->Toplevel;
$MW->{'.top'}->title('Sphere Flake Frustum Coverage Culling');
# Create some frames
$MW->{'.top.f1'} = $MW->{'.top'}->Frame;
$MW->{'.top.f2'} = $MW->{'.top'}->Frame;
foreach $_ (($MW->{'.top.f1'},$MW->{'.top.f2'}))
 {
  $_->pack('-side','left','-expand',1,'-fill','both');
 }
# Create the TkRenderWidget
$renWin = Graphics::VTK::RenderWindow->new;
$MW->{'.top.f1.rw'} = $MW->{'.top.f1'}->vtkInteractor('-rw',$renWin,'-width',500,'-height',500);
#BindTkRenderWidget .top.f1.rw
$MW->{'.top.f1.rw'}->pack('-expand',1,'-fill','both');
# Create the renderer and add it to the render window
$ren1 = Graphics::VTK::Renderer->new;
$renWin = $MW->{'.top.f1.rw'}->GetRenderWindow;
$renWin->AddRenderer($ren1);
# Create the initial flake list - it has one sphere at
# (0.0, 0.0, 0.0) with a radius of 1.0 and a color of
# (0.8, 0.2, 0.8)
@sphere = ( qw/ 0.0 0.0 0.0 1.0 0.8 0.2 0.8 /);
@$flake_list = ( \@sphere );;
# Create a transform that will be used in the AddSpheres proc
$t = Graphics::VTK::Transform->new;
# Take the flake list, and for each sphere of the specified
# radius, add nine more spheres around it
#
sub AddSpheres
{
 my $flake_list = shift;
 my $radius = shift;
 my $cb;
 my $cg;
 my $cr;
 my $i;
 my $new_list;
 my $new_r;
 my $new_x;
 my $new_y;
 my $new_z;
 my @point;
 my $r;
 my $s;
 my $x;
 my $x_angle;
 my $y;
 my $y_angle;
 my $z;
 $new_list = [];
 foreach $s (@$flake_list)
  {
   $x = $s->[0];
   $y = $s->[1];
   $z = $s->[2];
   $r = $s->[3];
   push @$new_list, $s;
   if ($r == $radius)
    {
     $x_angle = -80;
     $y_angle = 0;
     $new_r = $r / 5.0;
     for ($i = 0; $i < 9; $i += 1)
      {
       $t->Identity;

       $t->RotateY($y_angle);
       $t->RotateX($x_angle);
       @point = $t->TransformPoint(0,0,1);

       $new_x = ($x + $point[0] * ($r * 1.5));
       $new_y = ($y + $point[1] * ($r * 1.5));
       $new_z = ($z + $point[2] * ($r * 1.5));
       if ($i == 0)
        {
         $cr = 1.0;
         $cg = 0.0;
         $cb = 0.0;
        }
       elsif ($i == 1)
        {
         $cr = 1.0;
         $cg = 0.4;
         $cb = 0.0;
        }
       elsif ($i == 2)
        {
         $cr = 1.0;
         $cg = 1.0;
         $cb = 0.2;
        }
       elsif ($i == 3)
        {
         $cr = 0.5;
         $cg = 1.0;
         $cb = 0.4;
        }
       elsif ($i == 4)
        {
         $cr = 0.0;
         $cg = 0.8;
         $cb = 0.0;
        }
       elsif ($i == 5)
        {
         $cr = 0.0;
         $cg = 0.8;
         $cb = 1.0;
        }
       elsif ($i == 6)
        {
         $cr = 0.0;
         $cg = 0.0;
         $cb = 1.0;
        }
       elsif ($i == 7)
        {
         $cr = 0.5;
         $cg = 0.0;
         $cb = 1.0;
        }
       elsif ($i == 8)
        {
         $cr = 1.0;
         $cg = 0.0;
         $cb = 1.0;
        }
       push @$new_list, [ $new_x, $new_y,$new_z,$new_r,$cr,$cg,$cb];
       $x_angle = $x_angle + 20.0;
       $y_angle = $y_angle - 70.0;
      }
    }
  }
 return $new_list;
}
# Take the initial sphere list and add spheres recursively
$r = 1.0;
for ($i = 0; $i < 3; $i += 1)
 {
  $flake_list = AddSpheres($flake_list,$r);
  $r = $r / 5.0;
 }
## Create the high resolution sphere source and mapper
$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetCenter(0.0,0.0,0.0);
$sphere->SetRadius(1.0);
$sphere->SetThetaResolution($high_res);
$sphere->SetPhiResolution($high_res);
$mapper = Graphics::VTK::PolyDataMapper->new;
$mapper->SetInput($sphere->GetOutput);
## Create the medium resolution sphere source and mapper
$med_res_sphere = Graphics::VTK::SphereSource->new;
$med_res_sphere->SetCenter(0.0,0.0,0.0);
$med_res_sphere->SetRadius(1.0);
$med_res_sphere->SetThetaResolution($med_res);
$med_res_sphere->SetPhiResolution($med_res);
$med_res_mapper = Graphics::VTK::PolyDataMapper->new;
$med_res_mapper->SetInput($med_res_sphere->GetOutput);
## Create the low resolution sphere source and mapper
$low_res_sphere = Graphics::VTK::SphereSource->new;
$low_res_sphere->SetCenter(0.0,0.0,0.0);
$low_res_sphere->SetRadius(1.0);
$low_res_sphere->SetThetaResolution($low_res);
$low_res_sphere->SetPhiResolution($low_res);
$low_res_mapper = Graphics::VTK::PolyDataMapper->new;
$low_res_mapper->SetInput($low_res_sphere->GetOutput);
## Add all the actors - one for each sphere in the flake list
$i = 0;
foreach $s (@$flake_list)
 {
  $property_{$i} = Graphics::VTK::Property->new;
  $r = $s->[4];
  $g = $s->[5];
  $b = $s->[6];
  $property_{$i}->SetColor($r,$g,$b);
  $property_{$i}->SetOpacity(0.5);
  $property_{$i}->SetAmbient(0.1);
  $property_{$i}->SetDiffuse(0.9);
  $property_{$i}->SetSpecular(0.2);
  $actor_{$i} = Graphics::VTK::LODProp3D->new;
  $actor_{$i}->AddLOD($mapper,$property_{$i},0.0);
  $actor_{$i}->AddLOD($low_res_mapper,$property_{$i},0.0);
  $actor_{$i}->AddLOD($med_res_mapper,$property_{$i},0.0);
  $actor_{$i}->SetPosition($s->[0],$s->[1],$s->[2]);
  $actor_{$i}->SetScale($s->[3],$s->[3],$s->[3]);
  $ren1->AddProp($actor_{$i});
  $i += 1;
 }
## Get the culler from the renderer
$ren1->GetCullers->InitTraversal;
$culler = $ren1->GetCullers->GetNextItem;
$culler->SetSortingStyleToBackToFront;
## Create some UI stuff for controling things
$MW->{'.top.f2.f1'} = $MW->{'.top.f2'}->Frame('-relief','groove','-bg','#6600ff','-bd',2);
$MW->{'.top.f2.f2'} = $MW->{'.top.f2'}->Frame('-relief','groove','-bg','#6600ff','-bd',2);
$MW->{'.top.f2.f3'} = $MW->{'.top.f2'}->Frame('-relief','groove','-bg','#6600ff','-bd',2);
foreach $_ (($MW->{'.top.f2.f1'},$MW->{'.top.f2.f2'},$MW->{'.top.f2.f3'}))
 {
  $_->pack('-side','top','-expand',1,'-fill','both');
 }
$MW->{'.top.f2.f1.s1'} = $MW->{'.top.f2.f1'}->Scale('-fg','#ccffcc','-troughcolor','#334433','-to',8,'-variable',\$low_res,'-orient','horizontal','-from',3,'-bg','#000000','-label'," Low Res Sphere: ",'-activebackground','#000000','-length',200);
$MW->{'.top.f2.f1.s2'} = $MW->{'.top.f2.f1'}->Scale('-fg','#ccffcc','-troughcolor','#334433','-to',15,'-variable',\$med_res,'-orient','horizontal','-bg','#000000','-from',9,'-label'," Med Res Sphere: ",'-activebackground','#000000','-length',200);
$MW->{'.top.f2.f1.s3'} = $MW->{'.top.f2.f1'}->Scale('-fg','#ccffcc','-troughcolor','#334433','-to',30,'-variable',\$high_res,'-orient','horizontal','-bg','#000000','-from',16,'-label',"High Res Sphere: ",'-activebackground','#000000','-length',200);
$MW->{'.top.f2.f1.s1'}->bind('<ButtonRelease>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   $low_res_sphere->SetThetaResolution($low_res);
   $low_res_sphere->SetPhiResolution($low_res);
   $renWin->Render;
  }
);
$MW->{'.top.f2.f1.s2'}->bind('<ButtonRelease>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   $med_res_sphere->SetThetaResolution($med_res);
   $med_res_sphere->SetPhiResolution($med_res);
   $renWin->Render;
  }
);
$MW->{'.top.f2.f1.s3'}->bind('<ButtonRelease>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   $sphere->SetThetaResolution($high_res);
   $sphere->SetPhiResolution($high_res);
   $renWin->Render;
  }
);
foreach $_ (($MW->{'.top.f2.f1.s1'},$MW->{'.top.f2.f1.s2'},$MW->{'.top.f2.f1.s3'}))
 {
  $_->pack('-side','top','-expand',1,'-fill','both');
 }
$min_coverage = $culler->GetMinimumCoverage;
$max_coverage = $culler->GetMaximumCoverage;
$MW->{'.top.f2.f2.s1'} = $MW->{'.top.f2.f2'}->Scale('-fg','#ccffcc','-troughcolor','#334433','-to',0.0010,'-variable',\$min_coverage,'-orient','horizontal','-bg','#000000','-from',0.0000,'-label',"Minumum Coverage: ",'-activebackground','#000000','-resolution',0.00001,'-length',200);
$MW->{'.top.f2.f2.s2'} = $MW->{'.top.f2.f2'}->Scale('-fg','#ccffcc','-troughcolor','#334433','-to',1.0,'-variable',\$max_coverage,'-orient','horizontal','-bg','#000000','-from',0.01,'-label',"Maximum Coverage: ",'-activebackground','#000000','-resolution',0.01,'-length',200);
$MW->{'.top.f2.f2.s1'}->bind('<ButtonRelease>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   # Global Variables Declared for this function: culler
   $culler->SetMinimumCoverage($min_coverage);
   $renWin->Render;
  }
);
$MW->{'.top.f2.f2.s2'}->bind('<ButtonRelease>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   # Global Variables Declared for this function: culler
   $culler->SetMaximumCoverage($max_coverage);
   $renWin->Render;
  }
);
foreach $_ (($MW->{'.top.f2.f2.s1'},$MW->{'.top.f2.f2.s2'}))
 {
  $_->pack('-side','top','-expand',1,'-fill','both');
 }
$MW->{'.top.f2.f3.b1'} = $MW->{'.top.f2.f3'}->Button('-fg','#ccffcc','-activeforeground','#55ff55','-text',"Quit",'-bd',3,'-command',
 sub
  {
   exit();
  }
,'-bg','#000000','-activebackground','#000000');
$MW->{'.top.f2.f3.b1'}->pack('-expand',1,'-fill','both');
#
sub TkCheckAbort
{
 my $foo;
 $foo = $renWin->GetEventPending;
 $renWin->SetAbortRender(1) if ($foo != 0);
}
$renWin->SetAbortCheckMethod(
 sub
  {
   TkCheckAbort();
  }
);
#renWin SetFileName sphereFlake.tcl.ppm
#renWin SaveImageAsPPM

Tk->MainLoop;
