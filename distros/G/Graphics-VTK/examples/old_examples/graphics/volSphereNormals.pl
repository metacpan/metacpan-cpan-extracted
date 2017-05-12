#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;

$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#
#source TkInteractor.tcl
#
$recursion_depth = 3;
#
$triangle_count = 0;
$point_count = 0;
#
#
sub AddNextLevel
{
 my $in_vl = shift;
 my $lappend;
 my $norm;
 my $out_vl;
 my $p1;
 my $p12x;
 my $p12y;
 my $p12z;
 my $p1x;
 my $p1y;
 my $p1z;
 my $p2;
 my $p23x;
 my $p23y;
 my $p23z;
 my $p2x;
 my $p2y;
 my $p2z;
 my $p3;
 my $p31x;
 my $p31y;
 my $p31z;
 my $p3x;
 my $p3y;
 my $p3z;
 my $return;
 my $subst;
 my $t;
 #
 $out_vl = '';
 #
 foreach $t ($in_vl)
  {
   $p1 = $t[0];
   $p2 = $t[1];
   $p3 = $t[2];
   #
   $p1x = $p1[0];
   $p1y = $p1[1];
   $p1z = $p1[2];
   #
   $p2x = $p2[0];
   $p2y = $p2[1];
   $p2z = $p2[2];
   #
   $p3x = $p3[0];
   $p3y = $p3[1];
   $p3z = $p3[2];
   #
   $p12x = ($p1x + $p2x) / 2.0;
   $p12y = ($p1y + $p2y) / 2.0;
   $p12z = ($p1z + $p2z) / 2.0;
   #
   $p23x = ($p2x + $p3x) / 2.0;
   $p23y = ($p2y + $p3y) / 2.0;
   $p23z = ($p2z + $p3z) / 2.0;
   #
   $p31x = ($p3x + $p1x) / 2.0;
   $p31y = ($p3y + $p1y) / 2.0;
   $p31z = ($p3z + $p1z) / 2.0;
   #
   $norm = sqrt($p12x * $p12x + $p12y * $p12y + $p12z * $p12z);
   $p12x = $p12x / $norm;
   $p12y = $p12y / $norm;
   $p12z = $p12z / $norm;
   #
   $norm = sqrt($p23x * $p23x + $p23y * $p23y + $p23z * $p23z);
   $p23x = $p23x / $norm;
   $p23y = $p23y / $norm;
   $p23z = $p23z / $norm;
   #
   $norm = sqrt($p31x * $p31x + $p31y * $p31y + $p31z * $p31z);
   $p31x = $p31x / $norm;
   $p31y = $p31y / $norm;
   $p31z = $p31z / $norm;
   #
   $out_vl = $lappend->out_vl($subst->ARRAY_0x89bd370_);
   #
   $out_vl = $lappend->out_vl($subst->ARRAY_0x8a5a518_);
   #
   $out_vl = $lappend->out_vl($subst->ARRAY_0x8a5a4d0_);
   #
   $out_vl = $lappend->out_vl($subst->ARRAY_0x8a5a5b4_);
  }
 #
 return $out_vl;
}
#
#
sub AddPoints
{
 my $vl = shift;
 my $points;
 my $t;
 my $v;
 # Global Variables Declared for this function: point_count
 #
 foreach $t ($vl)
  {
   foreach $v ($t)
    {
     $points->InsertPoint($point_count,$v[0],$v[1],$v[2]);
     $point_count += 1;
    }
  }
}
#
#
sub AddTriangles
{
 my $vl = shift;
 my $i;
 my $llength;
 my $num_tris;
 my $triangles;
 # Global Variables Declared for this function: triangle_count
 #
 $num_tris = $llength->_vl;
 #
 for ($i = 0; $i < $num_tris; $i += 1)
  {
   $triangles->InsertNextCell(4);
   $triangles->InsertCellPoint($triangle_count * 3);
   $triangles->InsertCellPoint($triangle_count * 3 + 1);
   $triangles->InsertCellPoint($triangle_count * 3 + 2);
   $triangles->InsertCellPoint($triangle_count * 3);
  }
}
#
#
sub MakeSphere
{
 my $AddNextLevel;
 my $AddPoints;
 my $AddTriangles;
 my $i;
 my $initial_list;
 my $lappend;
 my $list;
 my $points;
 my $sphereMapper;
 my $spherePolyData;
 my $t1;
 my $t2;
 my $t3;
 my $tmp_list;
 my $tmp_list2;
 my $triangles;
 my $vertex_list;
 # Global Variables Declared for this function: recursion_depth
 # Global Variables Declared for this function: triangle_count
 # Global Variables Declared for this function: point_count
 #
 $points->SetNumberOfPoints(0);
 $triangles->Reset;
 #
 $triangle_count = 0;
 $point_count = 0;
 #
 $initial_list = '';
 #
 $initial_list = $lappend->initial_list([' 0 1 0 ',' 1 0 0 ',' 0 0 1 ']);
 $initial_list = $lappend->initial_list([' 0 1 0 ',' 0 0 1 ',' -1 0 0 ']);
 $initial_list = $lappend->initial_list([' 0 1 0 ',' -1 0 0 ',' 0 0 -1 ']);
 $initial_list = $lappend->initial_list([' 0 1 0 ',' 0 0 -1 ',' 1 0 0 ']);
 #
 $initial_list = $lappend->initial_list([' 0 -1 0 ',' 1 0 0 ',' 0 0 1 ']);
 $initial_list = $lappend->initial_list([' 0 -1 0 ',' 0 0 1 ',' -1 0 0 ']);
 $initial_list = $lappend->initial_list([' 0 -1 0 ',' -1 0 0 ',' 0 0 -1 ']);
 $initial_list = $lappend->initial_list([' 0 -1 0 ',' 0 0 -1 ',' 1 0 0 ']);
 #
 if ($recursion_depth < 2)
  {
   $vertex_list = $initial_list;
   #
   for ($i = 0; $i < $recursion_depth; $i += 1)
    {
     $vertex_list = AddNextLevel($vertex_list);
    }
   #
   AddPoints($vertex_list);
   AddTriangles($vertex_list);
  }
 else
  {
   foreach $t1 ($initial_list)
    {
     $tmp_list = AddNextLevel($list->_t1);
     foreach $t2 ($tmp_list)
      {
       $tmp_list2 = AddNextLevel($list->_t2);
       foreach $t3 ($tmp_list2)
        {
         $vertex_list = $list->_t3;
         for ($i = 0; $i < $recursion_depth - 2; $i += 1)
          {
           $vertex_list = AddNextLevel($vertex_list);
          }
         AddPoints($vertex_list);
         AddTriangles($vertex_list);
        }
      }
    }
  }
 #
 $sphereMapper->Modified;
 $spherePolyData->Modified;
}
#
# Simple volume rendering example.
$reader = Graphics::VTK::SLCReader->new;
$reader->SetFileName("$VTK_DATA/sphere.slc");
#
# Create transfer functions for opacity and color
$opacityTransferFunction = Graphics::VTK::PiecewiseFunction->new;
$opacityTransferFunction->AddPoint(100,0.0);
$opacityTransferFunction->AddPoint(128,1.0);
#
$colorTransferFunction = Graphics::VTK::PiecewiseFunction->new;
$colorTransferFunction->AddPoint(0.0,1.0);
$colorTransferFunction->AddPoint(255.0,1.0);
#
$gradtf = Graphics::VTK::PiecewiseFunction->new;
$gradtf->AddPoint(0.0,0.0);
$gradtf->AddPoint(1.0,1.0);
#
# Create properties, mappers, volume actors, and ray cast function
$volumeProperty = Graphics::VTK::VolumeProperty->new;
$volumeProperty->SetColor(@Graphics::VTK::Colors::colorTransferFunction);
$volumeProperty->SetScalarOpacity($opacityTransferFunction);
$volumeProperty->ShadeOn;
$volumeProperty->SetInterpolationTypeToLinear;
#
#
$directionEncoder = Graphics::VTK::RecursiveSphereDirectionEncoder->new;
$directionEncoder->SetRecursionDepth($recursion_depth);
#
$compositeFunction = Graphics::VTK::VolumeRayCastCompositeFunction->new;
#
$volumeMapper = Graphics::VTK::VolumeRayCastMapper->new;
$volumeMapper->SetInput($reader->GetOutput);
$volumeMapper->SetVolumeRayCastFunction($compositeFunction);
$volumeMapper->GetGradientEstimator->SetDirectionEncoder($directionEncoder);
#
$volume = Graphics::VTK::Volume->new;
$volume->SetMapper($volumeMapper);
$volume->SetProperty($volumeProperty);
#
# Create outline
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($reader->GetOutput);
#
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
#
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineActor->GetProperty->SetColor(1,1,1);
#
#
$points = Graphics::VTK::Points->new;
$triangles = Graphics::VTK::CellArray->new;
#
$spherePolyData = Graphics::VTK::PolyData->new;
$spherePolyData->SetPoints($points);
$spherePolyData->SetPolys($triangles);
#
$cleaner = Graphics::VTK::CleanPolyData->new;
$cleaner->SetInput($spherePolyData);
#
$normals = Graphics::VTK::PolyDataNormals->new;
$normals->SetInput($cleaner->GetOutput);
$normals->FlipNormalsOn;
#
$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($normals->GetOutput);
#
$sphereActor = Graphics::VTK::Actor->new;
$sphereActor->SetMapper($sphereMapper);
$sphereActor->GetProperty->SetColor(1.0,1.0,1.0);
$sphereActor->GetProperty->SetAmbient(0.3);
$sphereActor->GetProperty->SetDiffuse(0.7);
$sphereActor->GetProperty->SetRepresentationToWireframe;
#
MakeSphere();
#
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
#
$ren1->AddActor($outlineActor);
$ren1->AddVolume($volume);
$ren1->SetBackground(0.1,0.2,0.4);
#
$ren2 = Graphics::VTK::Renderer->new;
$renWin2 = Graphics::VTK::RenderWindow->new;
$renWin2->AddRenderer($ren2);
#
$ren2->AddActor($sphereActor);
$ren2->SetBackground(0.1,0.2,0.4);
#
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
#
#
sub pow
{
 my $a = shift;
 my $b = shift;
 my $c;
 my $i;
 my $return;
 #
 $c = 1;
 #
 for ($i = 0; $i < $b; $i += 1)
  {
   $c = $c * $a;
  }
 #
 return $c;
}
#
#
sub SetInfoLabel
{
 my $dirs;
 my $outer_size;
 my $pow;
 my $unique;
 # Global Variables Declared for this function: recursion_depth
 #
 $dirs = $directionEncoder->GetNumberOfEncodedDirections;
 $outer_size = pow(2,$recursion_depth) + 1;
 $unique = $dirs - 1 - $outer_size * 4 + 4;
 #
 $MW->{'.top.f3.info'}->config('-text',"At a recursion depth of $recursion_depth there
are $dirs encoded directions. This is 
$unique unique directions, [expr $dirs - $unique - 1] 
duplicated directions on the z=0 plane, 
and 1 encoded index for the zero normal.
");
}
#
#
$MW->{'.top'} = $MW->Toplevel('-visual','truecolor');
$MW->{'.top'}->MainWindow->title('Recursive Sphere Normal Encoding');
#
$MW->{'.top.f1'} = $MW->{'.top'}->Frame('-bg','#193264','-bd',0);
$MW->{'.top.f2'} = $MW->{'.top'}->Frame('-bg','#193264','-bd',0);
$MW->{'.top.f3'} = $MW->{'.top'}->Frame('-bg','#193264','-bd',0);
foreach $_ (($MW->{'.top.f1'},$MW->{'.top.f2'},$MW->{'.top.f3'}))
 {
  $_->pack('-side','left','-expand',1,'-fill','both');
 }
#
$MW->{'.top.f1.rw'} = Graphics::VTK::TkRenderWidget->new('-width',200,'-height',200,'-rw',$renWin);
$BindTkRenderWidget->_top_f1_rw;
$MW->{'.top.f1.rw'}->pack('-side','top','-expand',1,'-fill','both');
#
$MW->{'.top.f1.info'} = $MW->{'.top.f1'}->Label('-fg','#aaaaaa','-bg','#193264','-text',"A 50x50x50 volume created 
from the sphere distance 
function, rendered with 
trilinear interpolation,
shading, and scalar opacity 
compositing.",'-font','Helvetica -12 bold');
$MW->{'.top.f1.info'}->pack('-side','top','-expand',1,'-fill','both');
#
$MW->{'.top.f2.rw'} = Graphics::VTK::TkRenderWidget->new('-width',200,'-height',200,'-rw',$renWin2);
$BindTkRenderWidget->_top_f2_rw;
$MW->{'.top.f2.rw'}->pack('-side','top','-expand',1,'-fill','both');
#
$MW->{'.top.f2.info'} = $MW->{'.top.f2'}->Label('-fg','#aaaaaa','-bg','#193264','-text',"This wireframe sphere
represents the direction
encoding. Each vertex has
an index. A direction is
encoded into the index of
the closest vertex.",'-font','Helvetica -12 bold');
#
$MW->{'.top.f2.info'}->pack('-side','top','-expand',1,'-fill','both');
#
$MW->{'.top.f3.info'} = $MW->{'.top.f3'}->Label('-fg','#aaaaaa','-bg','#193264','-text',"hello world",'-justify','left','-font','Helvetica -12 bold','-bd',0);
#
$MW->{'.top.f3.info'}->pack('-side','top','-expand',0,'-fill','both','-padx',10,'-pady',10);
SetInfoLabel();
#
$MW->{'.top.f3.level'} = $MW->{'.top.f3'}->Scale('-fg','#aaaaaa','-troughcolor','#777777','-highlightthickness',0,'-font','Helvetica -12 bold','-bd',0,'-to',6,'-variable',\$recursion_depth,'-orient','horizontal','-from',0,'-bg','#193264','-label',"Recursion Depth",'-activebackground','#385284','-length',200);
#
#
$MW->{'.top.f3.level'}->pack('-side','top','-expand',0,'-fill','both','-padx',10,'-pady',10);
#
$MW->{'.top.f3.working'} = $MW->{'.top.f3'}->Label('-fg','#ff3333','-text',"",'-justify','center','-font','Helvetica -12 bold','-bg','#193264');
$MW->{'.top.f3.working'}->pack('-side','top','-expand',0,'-fill','both','-padx',10,'-pady',10);
#
$MW->{'.top.f3.timeinfo'} = $MW->{'.top.f3'}->Label('-fg','#ff3333','-text',"",'-justify','center','-font','Helvetica -12 bold','-bg','#193264');
$MW->{'.top.f3.timeinfo'}->pack('-side','top','-expand',0,'-fill','both','-padx',10,'-pady',10);
#
#
$MW->{'.top.f3.level'}->bind('<ButtonRelease>',
 sub
  {
   my $w = shift;
   my $Ev = $w->XEvent;
   # Global Variables Declared for this function: working
   # Global Variables Declared for this function: recursion_depth
   #
   $MW->{'.top.f3.working'}->configure('-text',"Working");
   $MW->{'.top.f3.timeinfo'}->configure('-text',"(The wireframe sphere is generated 
in tcl, therefore this may take a 
few minutes at the highest levels.)");
   $working = 1;
   $MW->update;
   #
   $directionEncoder->SetRecursionDepth($recursion_depth);
   MakeSphere();
   SetInfoLabel();
   $renWin->Render;
   $renWin2->Render;
   #
   $MW->{'.top.f3.working'}->configure('-text',"");
   $MW->{'.top.f3.timeinfo'}->configure('-text',"");
   $MW->update;
  }
);
#
#renWin SetFileName "valid/volSphereNormals.tcl.ppm"
#renWin SaveImageAsPPM
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
