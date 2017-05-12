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
# Create the RenderWindow, Renderer and both Actors
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);
$byuReader = Graphics::VTK::BYUReader->new;
$byuReader->SetGeometryFileName("$VTK_DATA/teapot.g");
$byuMapper = Graphics::VTK::PolyDataMapper->new;
$byuMapper->SetInput($byuReader->GetOutput);
for ($i = 0; $i < 9; $i += 1)
 {
  $byuActor = Graphics::VTK::Actor->new($,'i');
  $byuActor->_('i','SetMapper',$byuMapper);
  $ren1->AddActor("byuActor$",'i');
  $hull = Graphics::VTK::Hull->new($,'i');
  $hull->_('i','SetInput',$byuReader->GetOutput);
  $hullMapper = Graphics::VTK::PolyDataMapper->new($,'i');
  $hullMapper->_('i','SetInput',$hull->_('i','GetOutput'));
  $hullActor = Graphics::VTK::Actor->new($,'i');
  $hullActor->_('i','SetMapper',"hullMapper$",'i');
  $hullActor->_('i','GetProperty')->SetColor(1,0,0);
  $hullActor->_('i','GetProperty')->SetAmbient(0.2);
  $hullActor->_('i','GetProperty')->SetDiffuse(0.8);
  $hullActor->_('i','GetProperty')->SetRepresentationToWireframe;
  $ren1->AddActor("hullActor$",'i');
 }
$byuReader->Update;
$diagonal = $byuActor0->GetLength;
$i = 0;
for ($j = -1; $j < 2; $j += 1)
 {
  for ($k = -1; $k < 2; $k += 1)
   {
    $byuActor->_('i','AddPosition',$k * $diagonal,$j * $diagonal,0);
    $hullActor->_('i','AddPosition',$k * $diagonal,$j * $diagonal,0);
    $i += 1;
   }
 }
$hull0->AddCubeFacePlanes;
$hull1->AddCubeEdgePlanes;
$hull2->AddCubeVertexPlanes;
$hull3->AddCubeFacePlanes;
$hull3->AddCubeEdgePlanes;
$hull3->AddCubeVertexPlanes;
$hull4->AddRecursiveSpherePlanes(0);
$hull5->AddRecursiveSpherePlanes(1);
$hull6->AddRecursiveSpherePlanes(2);
$hull7->AddRecursiveSpherePlanes(3);
$hull8->AddRecursiveSpherePlanes(4);
# Add the actors to the renderer, set the background and size
$ren1->SetBackground(0.1,0.2,0.4);
$renWin->SetSize(500,500);
# render the image
$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;
$renWin->Render;
$ren1->GetActiveCamera->Zoom(1.5);
$renWin->Render;
#renWin SetFileName "teapotHulls.tcl.ppm"
#renWin SaveImageAsPPM
# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
