#
# Translation of VTK's vtkInt.tcl script to perl
#
# This is used slightly differenctly than the tcl version, in that this
#  is a separate package that is called explicitly by using the Graphics::VTK::Tk::vtkInt::Interact routine
#
# See any of the VTK perl examples (such as ColorSph.pl) for the typical usage.

package Graphics::VTK::Tk::vtkInt;


## Literal translation of the vtkInt script to perl

use Tk;

# a generic interactor for tcl and vtk
#
@vtkInteractBold = ('-background', '#43ce80', '-foreground', '#221133', '-relief', 'raised', '-borderwidth', '1');
@vtkInteractNormal = ('-background', '#dddddd', '-foreground', '#221133', '-relief', 'flat');
$vtkInteractTagcount = 1;
@vtkInteractCommandList = ();
$vtkInteractCommandIndex = 0;
#
#
sub vtkInteract
{
 my $MW = shift; # window that the interactor is to be applied to
 $MW->update; # Somethings needed to kick start the graphics pipeline
 my $command_string;
 # Global Variables Declared for this function: vtkInteractCommandList, vtkInteractCommandIndex
 # Global Variables Declared for this function: vtkInteractTagcount
#
	sub dovtk
	 {
	  my $MW = shift;
	  my $s = shift;  # Command
	  my $w = shift;  # vtkInteract widget
	  my $tag;
	  my $tagnum;
	  # Global Variables Declared for this function: vtkInteractBold, vtkInteractNormal, vtkInteractTagcount
	  # Global Variables Declared for this function: vtkInteractCommandList, vtkInteractCommandIndex
	  #
	  $tag = $tagnum = $tagnum . $vtkInteractTagcount;
	  $vtkInteractCommandIndex = $vtkInteractTagcount;
	  $vtkInteractTagcount += 1;
	  $MW->{'.vtkInteract.display.text'}->configure('-state','normal');
	  $MW->{'.vtkInteract.display.text'}->insert('end',$s,$tag);
	  push @vtkInteractCommandList, $s;
	  $MW->{'.vtkInteract.display.text'}->tag('configure',$tag,$vtkInteractNormal);
	  $MW->{'.vtkInteract.display.text'}->tag('bind','<Any-Enter>',
	   sub
	    {
	     $MW->{'.vtkInteract.display.text'}->tag('configure',$tag,$vtkInteractBold);
	    }
	  );
	  $MW->{'.vtkInteract.display.text'}->tag('bind','<Any-Leave>',
	   sub
	    {
	     $MW->{'.vtkInteract.display.text'}->tag('configure',$tag,$vtkInteractNormal);
	    }
	  );
	  $MW->{'.vtkInteract.display.text'}->tag('bind','<1>',
	   sub
	    {
	     dovtk($MW,$s,$MW->{'.vtkInteract'});
	    }
	  );
	  $MW->{'.vtkInteract.display.text'}->insert('end',"\n");
	  $MW->{'.vtkInteract.display.text'}->insert('end',eval($s));
	  $MW->{'.vtkInteract.display.text'}->insert('end',"\n\n");
	  $MW->{'.vtkInteract.display.text'}->configure('-state','disabled');
	  $MW->{'.vtkInteract.display.text'}->yview('end');
	 };
 #
 $MW->{'.vtkInteract'}->destroy() if( defined( $MW->{'.vtkInteract'} ));
 $MW->{'.vtkInteract'} = $MW->Toplevel('-bg','#bbbbbb');
 $MW->{'.vtkInteract'}->MainWindow->title("vtk Interactor");
 $MW->{'.vtkInteract'}->MainWindow->iconname("vtk");
 #
 $MW->{'.vtkInteract.buttons'} = $MW->{'.vtkInteract'}->Frame('-bg','#bbbbbb');
 $MW->{'.vtkInteract.buttons'}->pack('-side','bottom','-fill','both','-expand',0,'-pady','2m');
 $MW->{'.vtkInteract.buttons.dismiss'} = $MW->{'.vtkInteract.buttons'}->Button('-fg','#221133','-bg','#bbbbbb','-activeforeground','#221133','-text','Dismiss','-activebackground','#cccccc','-command',sub{ $MW->{'.vtkInteract'}->withdraw});
 $MW->{'.vtkInteract.buttons.dismiss'}->pack('-side','left','-expand',1,'-fill','x');
 #
 $MW->{'.vtkInteract.file'} = $MW->{'.vtkInteract'}->Frame('-bg','#bbbbbb');
 $MW->{'.vtkInteract.file.label'} = $MW->{'.vtkInteract.file'}->Label('-anchor','w','-fg','#221133','-bg','#bbbbbb','-width',10,'-text',"Command:");
 $MW->{'.vtkInteract.file.entry'} = $MW->{'.vtkInteract.file'}->Entry('-fg','#221133','-bg','#dddddd','-highlightthickness',1,'-width',40,'-highlightcolor','#221133');
 $MW->{'.vtkInteract.file.entry'}->bind('<Return>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    dovtk($MW, $Ev->W->get,$MW->{'.vtkInteract'});
    $Ev->W->delete(0,'end');
   }
 );
 $MW->{'.vtkInteract.file.label'}->pack('-side','left');
 $MW->{'.vtkInteract.file.entry'}->pack('-side','left','-expand',1,'-fill','x');
 #
 $MW->{'.vtkInteract.display'} = $MW->{'.vtkInteract'}->Frame('-bg','#bbbbbb');
 $MW->{'.vtkInteract.display.text'} = $MW->{'.vtkInteract.display'}->Scrolled( 'Text', '-fg','#331144','-bg','#dddddd','-width',60, '-wrap','word','-height',8,'-state','disabled','-setgrid','true');
# $MW->{'.vtkInteract.display.scroll'} = $MW->{'.vtkInteract.display'}->Scrollbar('-bg','#bbbbbb','-highlightthickness',0,'-troughcolor','#bbbbbb','-activebackground','#cccccc','-command',sub{ $MW->{'.vtkInteract.display.text'}->yview});
 $MW->{'.vtkInteract.display.text'}->pack('-side','left','-expand',1,'-fill','both');
# $MW->{'.vtkInteract.display.scroll'}->pack('-side','left','-expand',0,'-fill','y');
 #
 $MW->{'.vtkInteract.display'}->pack('-side','bottom','-expand',1,'-fill','both');
 $MW->{'.vtkInteract.file'}->pack('-pady','3m','-padx','2m','-side','bottom','-fill','x');
 #
 $vtkInteractCommandIndex = 0;
 #
 $MW->{'.vtkInteract'}->bind('<Down>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    if ($vtkInteractCommandIndex < $vtkInteractTagcount - 1)
     {
      $vtkInteractCommandIndex += 1;
      $command_string = $vtkInteractCommandList[$vtkInteractCommandIndex];
      $MW->{'.vtkInteract.file.entry'}->delete(0,'end');
      $MW->{'.vtkInteract.file.entry'}->insert('end',$command_string);
     }
    elsif ($vtkInteractCommandIndex == $vtkInteractTagcount - 1)
     {
      $MW->{'.vtkInteract.file.entry'}->delete(0,'end');
     }
   }
 );
 #
 $MW->{'.vtkInteract'}->bind('<Up>',
  sub
   {
    my $w = shift;
    my $Ev = $w->XEvent;
    if ($vtkInteractCommandIndex > 0)
     {
      $vtkInteractCommandIndex = $vtkInteractCommandIndex - 1;
      $command_string = $vtkInteractCommandList[$vtkInteractCommandIndex];
      $MW->{'.vtkInteract.file.entry'}->delete(0,'end');
      $MW->{'.vtkInteract.file.entry'}->insert('end',$command_string);
     }
   }
 );
 #
 $MW->{'.vtkInteract'}->withdraw;
}


1;
