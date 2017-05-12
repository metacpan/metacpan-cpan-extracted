#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;



use Graphics::VTK::Tk::vtkInteractor;


# This example creates a polygonal model of a mace made of a sphere
# and a set of cones adjusted on its surface using glyphing. 


# The sphere is rendered to the screen through the usual VTK render
# window but is included inside a standard Tk GUI comprising several
# other Tk widgets allowing the user to modify the VTK objects
# properties interactively. Interactions are performed through Tk
# events bindings instead of vtkRenderWindowInteractor.



# First we include the VTK Tcl packages which will make available 
# all of the vtk commands to Tcl

$VTK_DATA_ROOT = 0;
$VTK_DATA_ROOT = $ENV{VTK_DATA_ROOT};
use Graphics::VTK::Tk::vtkInt;


# Next we create an instance of vtkSphereSource and set some of its 
# properties

$sphere = Graphics::VTK::SphereSource->new;
$sphere->SetThetaResolution(8);
$sphere->SetPhiResolution(8);


# We create an instance of vtkPolyDataMapper to map the polygonal data 
# into graphics primitives. We connect the output of the sphere source
# to the input of this mapper 

$sphereMapper = Graphics::VTK::PolyDataMapper->new;
$sphereMapper->SetInput($sphere->GetOutput);


# Create an actor to represent the sphere. The actor coordinates rendering of
# the graphics primitives for a mapper. We set this actor's mapper to be
# the mapper which we created above.

$sphereActor = Graphics::VTK::Actor->new;
$sphereActor->SetMapper($sphereMapper);


# Next we create an instance of vtkConeSource that will be used to
# set the glyphs on the sphere's surface

$cone = Graphics::VTK::ConeSource->new;
$cone->SetResolution(6);


# Glyphing is a visualization technique that represents data by using
# symbol or glyphs. In VTK, the vtkGlyph3D class allows you to create
# glyphs that can be scaled, colored and oriented along a
# direction. The glyphs (here, cones) are copied at each point of the
# input dataset (the sphere's vertices).

# Create a vtkGlyph3D to dispatch the glyph/cone geometry (SetSource) on the
# sphere dataset (SetInput). Each glyph is oriented through the dataset 
# normals (SetVectorModeToUseNormal). The resulting dataset is a set
# of cones lying on a sphere surface.

$glyph = Graphics::VTK::Glyph3D->new;
$glyph->SetInput($sphere->GetOutput);
$glyph->SetSource($cone->GetOutput);
$glyph->SetVectorModeToUseNormal;
$glyph->SetScaleModeToScaleByVector;
$glyph->SetScaleFactor(0.25);


# We create an instance of vtkPolyDataMapper to map the polygonal data 
# into graphics primitives. We connect the output of the glyph3d
# to the input of this mapper 

$spikeMapper = Graphics::VTK::PolyDataMapper->new;
$spikeMapper->SetInput($glyph->GetOutput);


# Create an actor to represent the glyphs. The actor coordinates rendering of
# the graphics primitives for a mapper. We set this actor's mapper to be
# the mapper which we created above.

$spikeActor = Graphics::VTK::Actor->new;
$spikeActor->SetMapper($spikeMapper);


# Create the Renderer and assign actors to it. A renderer is like a
# viewport. It is part or all of a window on the screen and it is responsible
# for drawing the actors it has. We also set the background color here.

$renderer = Graphics::VTK::Renderer->new;
$renderer->AddActor($sphereActor);
$renderer->AddActor($spikeActor);
$renderer->SetBackground(1,1,1);


# We create the render window which will show up on the screen
# We put our renderer into the render window using AddRenderer. 
# Do not set the size of the window here.

$renWin = Graphics::VTK::RenderWindow->new;
$renWin->AddRenderer($renderer);


# vtkTkRenderWidget is a Tk widget that we can render into. It has a
# GetRenderWindow method that returns a vtkRenderWindow. This can then
# be used to create a vtkRenderer and etc. We can also specify a
# vtkRenderWindow to be used when creating the widget by using the -rw
# option, which is what we do here by using renWin. It also takes
# -width and -height options that can be used to specify the widget
# size, hence the render window size: we set the size to be 300
# pixels by 300. 

$vtkw = $MW->{'.ren'} = $MW->vtkInteractor('-rw',$renWin,'-width',300,'-height',300);


# When using the vtkTkWidget classes you should not use the interactor
# classes such as vtkRenderWindowInteractor. While it may work, the
# behavior may be unstable. Normally you should use either an
# interactor (see Mace.Tcl) or a vtkTkWidget but never both for a
# given window. Hopefully, events can be bound on this widget just like any
# other Tk widget. BindTkRenderWidget sets events handlers that are similar
# to what we would achieve using vtkRenderWindowInteractor.

#BindTkRenderWidget $vtkw


# Once the VTK widget has been created it can be inserted into a whole Tk GUI
# as well as any other standard Tk widgets. The code below will create several
# "scale" (sliders) widgets enabling us to control the mace parameters 
# interactively.



# We first create a .params Tk frame into which we will pack all sliders.


$MW->{'.params'} = $MW->Frame;


# Next we create a scale slider controlling the sphere Theta
# resolution. The value of this slider will range from 3 to 20 by
# increment 1 (-from, -to and -res options respectively). The
# orientation of this widget is horizontal (-orient option). We label
# it using the -label option. Finally, we bind the scale to Tcl code
# by assigning the -command option to the name of a Tcl
# procedure. Whenever the slider value changes this procedure will be
# called, enabling us to propagate this GUI setting to the
# corresponding VTK object.

$sth = $MW->{'.params.sth'} = $MW->{'.params'}->Scale('-from',3,'-res',1,'-label',"Sphere Theta Resolution:",'-to',20,'-command',
   \&setSphereThetaResolution
,'-orient','horizontal');


# The slider widget is initialized using the value obtained from the 
# corresponding VTK object (i.e. the sphere theta resolution).

$sth->set($sphere->GetThetaResolution);


# The procedure is called by the slider-widget handler whenever the
# slider value changes (either through user interaction or
# programmatically). It receives the slider value as parameter. We
# update the corresponding VTK object by calling the
# SetThetaResolution using this parameter and we render the scene to
# update the pipeline.

#
sub setSphereThetaResolution
{
 my $res = shift;
 $sphere->SetThetaResolution($res);
 $renWin->Render;
}


# In the exact same way we create a scale slider controlling the sphere Phi
# resolution. 

$sph = $MW->{'.params.sph'} = $MW->{'.params'}->Scale('-from',3,'-res',1,'-label',"Sphere Phi Resolution:",'-to',20,'-command',
   \&setSpherePhiResolution
,'-orient','horizontal');

$sph->set($sphere->GetPhiResolution);

#
sub setSpherePhiResolution
{
 my $res = shift;
 $sphere->SetPhiResolution($res);
 $renWin->Render;
}


# In the exact same way we create a scale slider controlling the cone
# resolution. 

$cre = $MW->{'.params.cre'} = $MW->{'.params'}->Scale('-from',3,'-res',1,'-label',"Cone Source Resolution:",'-to',20,'-command',
   \&setConeSourceResolution,
,'-orient','horizontal');

$cre->set($cone->GetResolution);

#
sub setConeSourceResolution
{
 my $res = shift;
 $cone->SetResolution($res);
 $renWin->Render;
}


# In the exact same way we create a scale slider controlling the glyph
# scale factor. 

$gsc = $MW->{'.params.gsc'} = $MW->{'.params'}->Scale('-from',0.1,'-res',0.05,'-label',"Glyph Scale Factor:",'-to',1.5,'-command',
   \&setGlyphScaleFactor,
,'-orient','horizontal');
$gsc->set($glyph->GetScaleFactor);

#
sub setGlyphScaleFactor
{
 my $factor = shift;
 $glyph->SetScaleFactor($factor);
 $renWin->Render;
}


# Let's add a quit button that will call the bye() (see below)

$MW->{'.params.quit'} = $MW->{'.params'}->Button('-text',"Quit",'-command',
 sub
  {
   bye();
  }
);



# Finally we pack all sliders on top of each other (-side top) inside
# the frame and we pack the VTK widget $vtkw and the frame .params
# inside the main root widget.

foreach $_ (($sth,$sph,$cre,$gsc,$MW->{'.params.quit'}))
 {
  $_->pack('-side','top','-anchor','nw','-fill','both');
 }
foreach $_ (($vtkw,$MW->{'.params'}))
 {
  $_->pack('-side','top','-fill','both','-expand','yes');
 }


# We set the window manager (wm command) so that it registers a
# command to handle the WM_DELETE_WINDOW protocal request. This
# request is triggered when the widget is closed using the standard
# window manager icons or buttons. In this case the 'bye' procedure
# will be called and it will free up any objects we created then exit
# the application.

$MW->protocol('WM_DELETE_WINDOW',\&bye);
#
sub bye
{
 exit();
}


# You only need this line if you run this script from a Tcl shell
# (tclsh) instead of a Tk shell (wish) 

#tkwait window .
Graphics::VTK::Tk::vtkInt::vtkInteract($MW);

Tk->MainLoop;
