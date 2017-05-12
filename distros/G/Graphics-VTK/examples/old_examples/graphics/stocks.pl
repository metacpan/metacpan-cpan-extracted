#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
# this is a tcl script for the stock case study
# get the interactor ui
use Graphics::VTK::Tk::vtkInt;
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
#create the outline
$apf = Graphics::VTK::AppendPolyData->new;
$olf = Graphics::VTK::OutlineFilter->new;
$olf->SetInput($apf->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($olf->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$zpos = 0;
# create the stocks
#
sub AddStock
{
 my $prefix = shift;
 my $name = shift;
 my $x = shift;
 my $y = shift;
 my $z = shift;
 # Global Variables Declared for this function: VTK_DATA
 # Global Variables Declared for this function: zpos
 # create labels
 $prefix = Graphics::VTK::VectorText->new('.TextSrc');
 $prefix->_TextSrc('SetText',"$name");
 $prefix = Graphics::VTK::PolyDataMapper->new('.LabelMapper');
 $prefix->_LabelMapper('SetInput',$prefix->_TextSrc('GetOutput'));
 $prefix = Graphics::VTK::Follower->new('.LabelActor');
 $prefix->_LabelActor('SetMapper',$prefix,'.LabelMapper');
 $prefix->_LabelActor('SetPosition',$x,$y,$z);
 $prefix->_LabelActor('SetScale',2,2,2);
 $prefix->_LabelActor('SetOrigin',$prefix->_LabelMapper('GetCenter'));
 # create a sphere source and actor
 $prefix = Graphics::VTK::PolyDataReader->new('.PolyDataRead');
 $prefix->_PolyDataRead('SetFileName',"$VTK_DATA/$prefix.vtk");
 $prefix = Graphics::VTK::RibbonFilter->new('.RibbonFilter');
 $prefix->_RibbonFilter('SetInput',$prefix->_PolyDataRead('GetOutput'));
 $prefix->_RibbonFilter('VaryWidthOn');
 $prefix->_RibbonFilter('SetWidthFactor',5);
 $prefix->_RibbonFilter('SetDefaultNormal',0,1,0);
 $prefix->_RibbonFilter('UseDefaultNormalOn');
 $prefix = Graphics::VTK::LinearExtrusionFilter->new('.Extrude');
 $prefix->_Extrude('SetInput',$prefix->_RibbonFilter('GetOutput'));
 $prefix->_Extrude('SetVector',0,1,0);
 $prefix->_Extrude('SetExtrusionType',1);
 $prefix->_Extrude('SetScaleFactor',0.7);
 #    vtkTubeFilter $prefix.TubeFilter
 #    $prefix.TubeFilter SetInput [$prefix.PolyDataRead GetOutput]
 #    $prefix.TubeFilter SetNumberOfSides 8
 #    $prefix.TubeFilter SetRadius 0.5
 #    $prefix.TubeFilter SetRadiusFactor 5
 #    $prefix.TubeFilter SetRadiusFactor 10000
 #    $prefix.TubeFilter SetVaryRadiusToVaryRadiusByScalar
 $prefix = Graphics::VTK::Transform->new('.Transform');
 $prefix->_Transform('Translate',0,0,$zpos);
 $prefix->_Transform('Scale',0.15,1,1);
 $prefix = Graphics::VTK::TransformPolyDataFilter->new('.TransformFilter');
 #    $prefix.TransformFilter SetInput [$prefix.TubeFilter GetOutput]
 $prefix->_TransformFilter('SetInput',$prefix->_Extrude('GetOutput'));
 $prefix->_TransformFilter('SetTransform',$prefix,'.Transform');
 # increment zpos
 $zpos = $zpos + 10;
 $prefix = Graphics::VTK::PolyDataMapper->new('.StockMapper');
 $prefix->_StockMapper('SetInput',$prefix->_TransformFilter('GetOutput'));
 $prefix = Graphics::VTK::Actor->new('.StockActor');
 $prefix->_StockActor('SetMapper',$prefix,'.StockMapper');
 $prefix->_StockMapper('SetScalarRange',0,8000);
 #    [$prefix.StockActor GetProperty] SetAmbient 0.5
 #    [$prefix.StockActor GetProperty] SetDiffuse 0.5
 $apf->AddInput($prefix->_TransformFilter('GetOutput'));
 $ren1->AddActor($prefix,'.StockActor');
 $ren1->AddActor($prefix,'.LabelActor');
 $prefix->_LabelActor('SetCamera',$ren1->GetActiveCamera);
}
# set up the stocks
AddStock('GE',"GE",104,55,3);
AddStock('GM',"GM",92,39,13);
AddStock('IBM',"IBM",96,80,17);
AddStock('DEC',"DEC",56,25,27);
# Add the actors to the renderer, set the background and size
$ren1->AddActor($outlineActor);
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(600,460);
#renWin SetSize 1200 600
# render the image
$ren1->GetActiveCamera->SetViewAngle(10);
$ren1->ResetCamera;
$ren1->GetActiveCamera->Zoom(1.9);
#[ren1 GetActiveCamera] Zoom 2.8
#[ren1 GetActiveCamera] Elevation 90
#[ren1 GetActiveCamera] SetViewUp 0 0 -1
$iren->Initialize;
#renWin SetFileName stocks.tcl.ppm
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
