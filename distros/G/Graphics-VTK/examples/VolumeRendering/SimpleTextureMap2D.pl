#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# This is a simple volume rendering example that
# uses a vtkVolumeRayCast mapper

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;

# Create the standard renderer, render window
# and interactor
$ren1 = Graphics::VTK::Renderer->new;
$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($ren1);
$iren = Graphics::VTK::RenderWindowInteractor->new;
$iren->SetRenderWindow($renWin);

# Create the reader for the data
$reader = Graphics::VTK::StructuredPointsReader->new;
$reader->SetFileName("$VTK_DATA_ROOT/Data/ironProt.vtk");

# Create transfer mapping scalar value to opacity
$opacityTransferFunction = Graphics::VTK::PiecewiseFunction->new;
$opacityTransferFunction->AddPoint(20,0.0);
$opacityTransferFunction->AddPoint(255,0.2);

# Create transfer mapping scalar value to color
$colorTransferFunction = Graphics::VTK::ColorTransferFunction->new;
$colorTransferFunction->AddRGBPoint(0.0,0.0,0.0,0.0);
$colorTransferFunction->AddRGBPoint(64.0,1.0,0.0,0.0);
$colorTransferFunction->AddRGBPoint(128.0,0.0,0.0,1.0);
$colorTransferFunction->AddRGBPoint(192.0,0.0,1.0,0.0);
$colorTransferFunction->AddRGBPoint(255.0,0.0,0.2,0.0);

# The property describes how the data will look
$volumeProperty = Graphics::VTK::VolumeProperty->new;
$volumeProperty->SetColor($colorTransferFunction);
$volumeProperty->SetScalarOpacity($opacityTransferFunction);

# The mapper knows how to render the data
$volumeMapper = Graphics::VTK::VolumeTextureMapper2D->new;
$volumeMapper->SetInput($reader->GetOutput);

# The volume holds the mapper and the property and
# can be used to position/orient the volume
$volume = Graphics::VTK::Volume->new;
$volume->SetMapper($volumeMapper);
$volume->SetProperty($volumeProperty);

$ren1->AddVolume($volume);
$renWin->Render;

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

$iren->SetUserMethod(
 sub
  {
   $MW->{'.vtkInteract'}->deiconify;
  }
);
$iren->Initialize;

$MW->withdraw;



Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
