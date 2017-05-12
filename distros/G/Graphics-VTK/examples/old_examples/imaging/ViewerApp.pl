#!/usr/local/bin/perl -w
#
use Graphics::VTK;



use Tk;
use Graphics::VTK::Tk;
$MW = Tk::MainWindow->new;

# For the purposes of this exercise, you only need to make changes in
# four places.  These are labeled with "#1", "#2", "#3", and "#4".
# This exercise allows you to create a small image processing application.
# You can add filters to the pipeline and turn them on an off via a user
# interface.  
# Try adding a vtkImageGradient and a vtkImageMagnitude after the default
# vtkImageGaussianSmooth. Time permitting, you might want to try a FlipFilter
# of a PadFilter as well.
# Default event bindings:
#     Mouse motion - Probes the input data, displaying pixel position and value
#     Left Mouse Button - Window/Level (Contrast/Brightness)
#     Right Mouse Button - Changes slices when mouse moved up/down
#     Keypress "r" - Resets the window/level to a default setting
$VTK_DATA = 0;
$VTK_DATA = $ENV{VTK_DATA};
#source vtkImageInclude.tcl
$source->ViewerAppTkImageViewerInteractor_tcl;
# Begin by setting up the Tk portion of the application
$MW->withdraw;
$MW->{'.top'} = $MW->Toplevel('-visual','best');
$MW->{'.top'}->title("Viz'99 VTK Imaging Exercise");
# menus
# menu .top.menu -type menubar
# menu .top.menu.file -tearoff 0
# menu .top.menu.filters -title "Filters"
# menu .top.menu.help -tearoff 0
$MW->{'.top.menu'}->cascade('-label',"File",'-menu','.top.menu.file');
$MW->{'.top.menu'}->cascade('-label',"Filters",'-menu','.top.menu.filters');
$MW->{'.top.menu'}->cascade('-label',"Help",'-menu','.top.menu.help');
$MW->{'.top.menu.file'}->command('-label',"Quit",'-command',
 sub
  {
   exit();
  }
);
$MW->{'.top.menu.help'}->command('-label',"User Interface",'-command',
 sub
  {
   HelpUI();
  }
);
# Helper proc
#
sub AddFilterMenuItem
{
 my $labelString = shift;
 my $command = shift;
 $MW->{'.top.menu.filters'}->checkbutton('-onvalue','on','-label',$labelString,'-offvalue','off','-command',"ActivateFilter $command",'-variable',\$$command);
}
# #1 -- To add a filter to the menu, call AddFilterMenuItem passing 
#       the "label" to use for the menu item and the name of your filter's 
#       instance. Example: Below is a filter called "gaussian" so we call 
#             AddFilterMenuItem Smoothing gaussian
AddFilterMenuItem('Smoothing','gaussian');
AddFilterMenuItem("Edge Directions",'gradient');
AddFilterMenuItem('Magnitude','magnitude');
AddFilterMenuItem("Flip Y",'flipY');
AddFilterMenuItem("Flip X",'flipX');
$MW->{'.top'}->configure('-menu','.top.menu');
# viewer frame
$MW->{'.top.f1'} = $MW->{'.top'}->Frame;
$viewer = Graphics::VTK::ImageViewer->new;
$MW->{'.top.f1.v1'} = $MW->{'.top.f1'}->vtkImageViewer('-width',512,'-height',512,'-iv',$viewer);
$MW->{'.top.f1.v1'}->pack('-padx',3,'-pady',3,'-side','left','-fill','both','-expand','t');
# annotation frames
$MW->{'.top.f2'} = $MW->{'.top'}->Frame;
$MW->{'.top.f2.f1'} = $MW->{'.top.f2'}->Frame;
$MW->{'.top.f2.f2'} = $MW->{'.top.f2'}->Frame;
$MW->{'.top.f2.f3'} = $MW->{'.top.f2'}->Frame;
$MW->{'.top.f2.f4'} = $MW->{'.top.f2'}->Frame;
$MW->{'.top.f2.f1.label'} = $MW->{'.top.f2.f1'}->Label('-relief','sunken');
$MW->{'.top.f2.f2.label'} = $MW->{'.top.f2.f2'}->Label('-relief','sunken');
$MW->{'.top.f2.f3.label'} = $MW->{'.top.f2.f3'}->Label('-relief','sunken');
$MW->{'.top.f2.f4.label'} = $MW->{'.top.f2.f4'}->Label('-relief','sunken');
$MW->{'.top.f2.f1.label'}->pack('-fill','x');
$MW->{'.top.f2.f2.label'}->pack('-fill','x');
$MW->{'.top.f2.f3.label'}->pack('-fill','x');
$MW->{'.top.f2.f4.label'}->pack('-fill','x');
foreach $_ (($MW->{'.top.f2.f1'},$MW->{'.top.f2.f2'},$MW->{'.top.f2.f3'},$MW->{'.top.f2.f4'}))
 {
  $_->pack('-fill','x','-side','left','-expand','t');
 }
$MW->{'.top.f1'}->pack('-fill','both','-expand','t');
$MW->{'.top.f2'}->pack('-fill','x');
# Set up the vtk imaging pipeline
$reader = Graphics::VTK::ImageReader->new;
$reader->SetDataByteOrderToLittleEndian;
$reader->SetDataExtent(0,255,0,255,1,93);
$reader->SetFilePrefix("$VTK_DATA/fullHead/headsq");
$reader->SetDataMask(0x7fff);
# #2 -- Try uncommenting the following line and running the script.
#       How does the load time change?  How does the performance change
#       when all the filters are off and you adjust the "slice" that is 
#       displayed (right mouse button, drag up/down)?
#reader Update
$gaussian = Graphics::VTK::ImageGaussianSmooth->new;
$gaussian->SetInput($reader->GetOutput);
$gaussian->SetStandardDeviations(2,2);
# #3 -- Add additional filters here. Turn BypassOn on each to start.
$gradient = Graphics::VTK::ImageGradient->new;
$gradient->SetInput($gaussian->GetOutput);
$magnitude = Graphics::VTK::ImageMagnitude->new;
$magnitude->SetInput($gradient->GetOutput);
$flipY = Graphics::VTK::ImageFlip->new;
$flipY->SetInput($magnitude->GetOutput);
$flipY->SetFilteredAxis(1);
$flipX = Graphics::VTK::ImageFlip->new;
$flipX->SetInput($flipY->GetOutput);
$flipX->SetFilteredAxis(0);
# #4 -- Set "lastfilter" to be the last filter in the pipeline
$lastFilter = $flipX;
# You shouldn't need to change anything below this point.
# grab the viewer from the TkImageViewerWidget
$viewer = $MW->{'.top.f1.v1'}->GetImageViewer;
$viewer->SetInput($lastFilter->GetOutput);
$viewer->SetZSlice(14);
$ResetTkImageViewer->_top_f1_v1;
# resize the widget to fit the size of the data
$dims = $reader->GetOutput->GetDimensions;
$MW->{'.top.f1.v1'}->configure('-width',$dims[0],'-height',$dims[1]);
# make interface
#BindTkImageViewer .top.f1.v1 
# tie labels to variables embedded in the Tk Widget
$MW->{'.top.f2.f1.label'}->configure('-textvariable',$GetWidgetVariable->_top_f1_v1('WindowLevelString'));
$MW->{'.top.f2.f2.label'}->configure('-textvariable',$GetWidgetVariable->_top_f1_v1('PixelPositionString'));
$MW->{'.top.f2.f3.label'}->configure('-textvariable',$GetWidgetVariable->_top_f1_v1('SliceString'));
# Procs for toggling filters
#
sub ActivateFilter
{
 my $filtername = shift;
 my $BypassOff;
 my $BypassOn;
 my $ResetTkImageViewer;
 my $catch;
 my $foo;
 my $upvar;
 # Global Variables Declared for this function: viewer
 $upvar->_filtername('filtermode');
 # make sure the filter exists
 $foo = $catch->_info_command__filtername______filtername;
 if ($foo == 1)
  {
   # filter exists
   if ($filtermode eq "off")
    {
     BypassOn($filtername);
    }
   else
    {
     BypassOff($filtername);
    }
   $ResetTkImageViewer->_top_f1_v1;
  }
}
# Help windows
#
sub HelpUI
{
 my $raise;
 if (defined('.help') ne ".help")
  {
   $MW->{'.help'} = $MW->Toplevel;
   $MW->{'.help'}->title("User Interface Help");
   $MW->{'.help.f1'} = $MW->{'.help'}->Frame;
   $MW->{'.help.f1.l0'} = $MW->{'.help.f1'}->Label('-padx',3,'-text',"UI Bindings",'-pady',3,'-font','bold');
   $MW->{'.help.f1.l1'} = $MW->{'.help.f1'}->Label('-padx',3,'-text',"
<Motion> - probe pixel
<B1> - Window/Level (Constrast/Brightness)
<B3> - Change slice
<KeyPress-r> - Reset window/level
	",'-pady',3);
   foreach $_ (($MW->{'.help.f1.l0'},$MW->{'.help.f1.l1'}))
    {
     $_->pack('-expand','t','-fill','both');
    }
   foreach $_ (())
    {
     $_->pack;
    }
  }
 else
  {
   $raise->_help;
  }
}
# to support the old bypass functionality these routines can be used
# as long as none of the filters in the pipline have multiple inputs.
# You must first call this routine to setup bypass functionality.
# Pass in the last filter (downstream) as well as that filter's 
# consumer (typically a mapper or writer)  Then the BypassOn and BypassOff
# procedures should work - Ken
#
sub SupportBypass
{
 my $lastFilter = shift;
 my $lastFiltersConsumer = shift;
 my $currentFilter;
 my $set;
 my $while;
 # create arrays of inputs, outputs and states
 # Global Variables Declared for this function: bypassState
 # Global Variables Declared for this function: bypassInputs
 # Global Variables Declared for this function: bypassOutputs
 $currentFilter = $lastFilter;
 $bypassState{$currentFilter} = 0;
 $bypassOutputs{$currentFilter} = $lastFiltersConsumer;
 $bypassState{$lastFiltersConsumer} = 0;
 $while->__currentFilter_GetNumberOfInputs____0("
      set bypassInputs($currentFilter) [[$currentFilter GetInput] GetSource]
      set bypassOutputs($bypassInputs($currentFilter)) $currentFilter
      set currentFilter $bypassInputs($currentFilter)
      set bypassState($currentFilter) 0
   ");
}
#
sub BypassOn
{
 my $filterName = shift;
 my $currentFilter;
 # Global Variables Declared for this function: bypassState
 # Global Variables Declared for this function: bypassInputs
 # Global Variables Declared for this function: bypassOutputs
 # only process if it isn't already bypassed ?
 if ($bypassState{$filterName} == 0)
  {
   # set this filters input to the next available downstream input
   $currentFilter = $bypassOutputs{$filterName};
   $currentFilter = $bypassOutputs{$currentFilter} while ($bypassState{$currentFilter} == 1);
   $currentFilter->SetInput($filterName->GetInput);
   $bypassState{$filterName} = 1;
  }
}
#
sub BypassOff
{
 my $filterName = shift;
 my $currentFilter;
 # Global Variables Declared for this function: bypassState
 # Global Variables Declared for this function: bypassInputs
 # Global Variables Declared for this function: bypassOutputs
 # only process if it is already bypassed ?
 if ($bypassState{$filterName} == 1)
  {
   # set this filters input to the next available upsream output
   $currentFilter = $bypassInputs{$filterName};
   $currentFilter = $bypassInputs{$currentFilter} while ($bypassState{$currentFilter} == 1);
   $filterName->SetInput($currentFilter->GetOutput);
   # set this filters input to the next available downstream input
   $currentFilter = $bypassOutputs{$filterName};
   $currentFilter = $bypassOutputs{$currentFilter} while ($bypassState{$currentFilter} == 1);
   $currentFilter->SetInput($filterName->GetOutput);
   $bypassState{$filterName} = 0;
  }
}
SupportBypass($flipX,$viewer->GetImageMapper);
BypassOn($gaussian);
BypassOn($gradient);
BypassOn($magnitude);
BypassOn($flipY);
BypassOn($flipX);

Tk->MainLoop;
