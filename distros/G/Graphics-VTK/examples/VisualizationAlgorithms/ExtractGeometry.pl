#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This example shows how to extract a piece of a dataset using an implicit 
# function. In this case the implicit function is formed by the boolean 
# combination of two ellipsoids.


$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# Here we create two ellipsoidal implicit functions and boolean them
# together tto form a "cross" shaped implicit function.
$quadric = Graphics::VTK::Quadric->new;
$quadric->SetCoefficients('.5',1,'.2',0,'.1',0,0,'.2',0,0);
$sample = Graphics::VTK::SampleFunction->new;
$sample->SetSampleDimensions(50,50,50);
$sample->SetImplicitFunction($quadric);
$sample->ComputeNormalsOff;
$trans = Graphics::VTK::Transform->new;
$trans->Scale(1,'.5','.333');
$sphere = Graphics::VTK::Sphere->new;
$sphere->SetRadius(0.25);
$sphere->SetTransform($trans);
$trans2 = Graphics::VTK::Transform->new;
$trans2->Scale('.25','.5',1.0);
$sphere2 = Graphics::VTK::Sphere->new;
$sphere2->SetRadius(0.25);
$sphere2->SetTransform($trans2);
$union = Graphics::VTK::ImplicitBoolean->new;
$union->AddFunction($sphere);
$union->AddFunction($sphere2);
$union->SetOperationType(0);
#union


# Here is where it gets interesting. The implicit function is used to
# extract those cells completely inside the function. They are then 
# shrunk to help show what was extracted.
$extract = Graphics::VTK::ExtractGeometry->new;
$extract->SetInput($sample->GetOutput);
$extract->SetImplicitFunction($union);
$shrink = Graphics::VTK::ShrinkFilter->new;
$shrink->SetInput($extract->GetOutput);
$shrink->SetShrinkFactor(0.5);
$dataMapper = Graphics::VTK::DataSetMapper->new;
$dataMapper->SetInput($shrink->GetOutput);
$dataActor = Graphics::VTK::Actor->new;
$dataActor->SetMapper($dataMapper);

# The outline gives context to the original data.
$outline = Graphics::VTK::OutlineFilter->new;
$outline->SetInput($sample->GetOutput);
$outlineMapper = Graphics::VTK::PolyDataMapper->new;
$outlineMapper->SetInput($outline->GetOutput);
$outlineActor = Graphics::VTK::Actor->new;
$outlineActor->SetMapper($outlineMapper);
$outlineProp = $outlineActor->GetProperty;
$outlineProp->SetColor(0,0,0);

# The usual rendering stuff is created.
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Add the actors to the renderer, set the background and size

$ren1->AddActor($outlineActor);
$ren1->AddActor($dataActor);
$ren1->SetBackground(1,1,1);
$renWin->SetSize(500,500);
$ren1->GetActiveCamera->Zoom(1.5);
$iren->Initialize;

# render the image

$iren->AddObserver('UserEvent',
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);

# prevent the tk window from showing up then start the event loop
$MW->withdraw;
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
