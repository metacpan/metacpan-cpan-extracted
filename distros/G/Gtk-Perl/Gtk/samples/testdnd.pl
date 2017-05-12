#!/usr/bin/perl -w

# TITLE: DND
# REQUIRES: Gtk

use Gtk;

@drag_icon_xpm = (
'36 48 9 1',
' 	c None',
'.	c #020204',
'+	c #8F8F90',
'@	c #D3D3D2',
'#	c #AEAEAC',
'$	c #ECECEC',
'%	c #A2A2A4',
'&	c #FEFEFC',
'*	c #BEBEBC',
'               .....................',
'              ..&&&&&&&&&&&&&&&&&&&.',
'             ...&&&&&&&&&&&&&&&&&&&.',
'            ..&.&&&&&&&&&&&&&&&&&&&.',
'           ..&&.&&&&&&&&&&&&&&&&&&&.',
'          ..&&&.&&&&&&&&&&&&&&&&&&&.',
'         ..&&&&.&&&&&&&&&&&&&&&&&&&.',
'        ..&&&&&.&&&@&&&&&&&&&&&&&&&.',
'       ..&&&&&&.*$%$+$&&&&&&&&&&&&&.',
'      ..&&&&&&&.%$%$+&&&&&&&&&&&&&&.',
'     ..&&&&&&&&.#&#@$&&&&&&&&&&&&&&.',
'    ..&&&&&&&&&.#$**#$&&&&&&&&&&&&&.',
'   ..&&&&&&&&&&.&@%&%$&&&&&&&&&&&&&.',
'  ..&&&&&&&&&&&.&&&&&&&&&&&&&&&&&&&.',
' ..&&&&&&&&&&&&.&&&&&&&&&&&&&&&&&&&.',
'................&$@&&&@&&&&&&&&&&&&.',
'.&&&&&&&+&&#@%#+@#@*$%$+$&&&&&&&&&&.',
'.&&&&&&&+&&#@#@&&@*%$%$+&&&&&&&&&&&.',
'.&&&&&&&+&$%&#@&#@@#&#@$&&&&&&&&&&&.',
'.&&&&&&@#@@$&*@&@#@#$**#$&&&&&&&&&&.',
'.&&&&&&&&&&&&&&&&&&&@%&%$&&&&&&&&&&.',
'.&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&.',
'.&&&&&&&&$#@@$&&&&&&&&&&&&&&&&&&&&&.',
'.&&&&&&&&&+&$+&$&@&$@&&$@&&&&&&&&&&.',
'.&&&&&&&&&+&&#@%#+@#@*$%&+$&&&&&&&&.',
'.&&&&&&&&&+&&#@#@&&@*%$%$+&&&&&&&&&.',
'.&&&&&&&&&+&$%&#@&#@@#&#@$&&&&&&&&&.',
'.&&&&&&&&@#@@$&*@&@#@#$#*#$&&&&&&&&.',
'.&&&&&&&&&&&&&&&&&&&&&$%&%$&&&&&&&&.',
'.&&&&&&&&&&$#@@$&&&&&&&&&&&&&&&&&&&.',
'.&&&&&&&&&&&+&$%&$$@&$@&&$@&&&&&&&&.',
'.&&&&&&&&&&&+&&#@%#+@#@*$%$+$&&&&&&.',
'.&&&&&&&&&&&+&&#@#@&&@*#$%$+&&&&&&&.',
'.&&&&&&&&&&&+&$+&*@&#@@#&#@$&&&&&&&.',
'.&&&&&&&&&&$%@@&&*@&@#@#$#*#&&&&&&&.',
'.&&&&&&&&&&&&&&&&&&&&&&&$%&%$&&&&&&.',
'.&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&.',
'.&&&&&&&&&&&&&&$#@@$&&&&&&&&&&&&&&&.',
'.&&&&&&&&&&&&&&&+&$%&$$@&$@&&$@&&&&.',
'.&&&&&&&&&&&&&&&+&&#@%#+@#@*$%$+$&&.',
'.&&&&&&&&&&&&&&&+&&#@#@&&@*#$%$+&&&.',
'.&&&&&&&&&&&&&&&+&$+&*@&#@@#&#@$&&&.',
'.&&&&&&&&&&&&&&$%@@&&*@&@#@#$#*#&&&.',
'.&&&&&&&&&&&&&&&&&&&&&&&&&&&$%&%$&&.',
'.&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&.',
'.&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&.',
'.&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&.',
'....................................');

@trashcan_closed_xpm = (
q{64 80 17 1},
q{ 	c None},
q{.	c #030304},
q{+	c #5A5A5C},
q{@	c #323231},
q{#	c #888888},
q{$	c #1E1E1F},
q{%	c #767677},
q{&	c #494949},
q{*	c #9E9E9C},
q{=	c #111111},
q{-	c #3C3C3D},
q{;	c #6B6B6B},
q{>	c #949494},
q{,	c #282828},
q{'	c #808080},
q{)	c #545454},
q{!	c #AEAEAC},
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                       ==......=$$...===                        },
q{                 ..$------)+++++++++++++@$$...                  },
q{             ..=@@-------&+++++++++++++++++++-....              },
q{          =.$$@@@-&&)++++)-,$$$$=@@&+++++++++++++,..$           },
q{         .$$$$@@&+++++++&$$$@@@@-&,$,-++++++++++;;;&..          },
q{        $$$$,@--&++++++&$$)++++++++-,$&++++++;%%'%%;;$@         },
q{       .-@@-@-&++++++++-@++++++++++++,-++++++;''%;;;%*-$        },
q{       +------++++++++++++++++++++++++++++++;;%%%;;##*!.        },
q{        =+----+++++++++++++++++++++++;;;;;;;;;;;;%'>>).         },
q{         .=)&+++++++++++++++++;;;;;;;;;;;;;;%''>>#>#@.          },
q{          =..=&++++++++++++;;;;;;;;;;;;;%###>>###+%==           },
q{           .&....=-+++++%;;####''''''''''##'%%%)..#.            },
q{           .+-++@....=,+%#####'%%%%%%%%%;@$-@-@*++!.            },
q{           .+-++-+++-&-@$$=$=......$,,,@;&)+!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           =+-++-+++-+++++++++!++++!++++!+++!++!+++=            },
q{            $.++-+++-+++++++++!++++!++++!+++!++!+.$             },
q{              =.++++++++++++++!++++!++++!+++!++.=               },
q{                 $..+++++++++++++++!++++++...$                  },
q{                      $$=.............=$$                       },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                });

@trashcan_open_xpm = (
q{64 80 17 1},
q{ 	c None},
q{.	c #030304},
q{+	c #5A5A5C},
q{@	c #323231},
q{#	c #888888},
q{$	c #1E1E1F},
q{%	c #767677},
q{&	c #494949},
q{*	c #9E9E9C},
q{=	c #111111},
q{-	c #3C3C3D},
q{;	c #6B6B6B},
q{>	c #949494},
q{,	c #282828},
q{'	c #808080},
q{)	c #545454},
q{!	c #AEAEAC},
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                      .=.==.,@                  },
q{                                   ==.,@-&&&)-=                 },
q{                                 .$@,&++;;;%>*-                 },
q{                               $,-+)+++%%;;'#+.                 },
q{                            =---+++++;%%%;%##@.                 },
q{                           @)++++++++;%%%%'#%$                  },
q{                         $&++++++++++;%%;%##@=                  },
q{                       ,-++++)+++++++;;;'#%)                    },
q{                      @+++&&--&)++++;;%'#'-.                    },
q{                    ,&++-@@,,,,-)++;;;'>'+,                     },
q{                  =-++&@$@&&&&-&+;;;%##%+@                      },
q{                =,)+)-,@@&+++++;;;;%##%&@                       },
q{               @--&&,,@&)++++++;;;;'#)@                         },
q{              ---&)-,@)+++++++;;;%''+,                          },
q{            $--&)+&$-+++++++;;;%%'';-                           },
q{           .,-&+++-$&++++++;;;%''%&=                            },
q{          $,-&)++)-@++++++;;%''%),                              },
q{         =,@&)++++&&+++++;%'''+$@&++++++                        },
q{        .$@-++++++++++++;'#';,........=$@&++++                  },
q{       =$@@&)+++++++++++'##-.................=&++               },
q{      .$$@-&)+++++++++;%#+$.....................=)+             },
q{      $$,@-)+++++++++;%;@=........................,+            },
q{     .$$@@-++++++++)-)@=............................            },
q{     $,@---)++++&)@===............................,.            },
q{    $-@---&)))-$$=..............................=)!.            },
q{     --&-&&,,$=,==...........................=&+++!.            },
q{      =,=$..=$+)+++++&@$=.............=$@&+++++!++!.            },
q{           .)-++-+++++++++++++++++++++++++++!++!++!.            },
q{           .+-++-+++++++++++++++++++++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!+++!!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           .+-++-+++-+++++++++!++++!++++!+++!++!++!.            },
q{           =+-++-+++-+++++++++!++++!++++!+++!++!+++=            },
q{            $.++-+++-+++++++++!++++!++++!+++!++!+.$             },
q{              =.++++++++++++++!++++!++++!+++!++.=               },
q{                 $..+++++++++++++++!++++++...$                  },
q{                      $$==...........==$$                       },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                },
q{                                                                });
#'

my ($have_drag);

use constant  TARGET_STRING => 0;
use constant  TARGET_ROOTWIN => 1;

@target_table = (
	{'target' => "STRING", 'flags' => 0, 'info' => TARGET_STRING},
	{'target' => "text/plain", 'flags' => 0, 'info' => TARGET_STRING},
	{'target' => "application/x-rootwin-drop", 'flags' => 0, 'info' => TARGET_ROOTWIN},
);

sub target_drag_leave {
  my ($widget, $context, $time) = @_;
  print "leave\n";
  $have_drag = 0;
  $widget->set($trashcan_closed, $trashcan_closed_mask);
}

sub target_drag_motion {
  my ($widget, $context, $x, $y, $time) = @_;
  my ($source_widget);

  if (!$have_drag)
    {
      $have_drag = 1;
      $widget->set( $trashcan_open, $trashcan_open_mask);
    }

  $source_widget = $context->get_source_widget ();
  printf("motion, source %s\n", $source_widget ?
	    ref($source_widget) : "unknown");

  $context->status ($context->suggested_action, $time);
  return 1;
}

sub target_drag_drop {
  my ($widget, $context, $x, $y, $time) = @_;
  my ($atom);
  print "drop\n";
  $have_drag = 0;

  $widget->set($trashcan_closed, $trashcan_closed_mask);

  if (($atom=$context->targets))
    {
      $widget->drag_get_data($context, $atom, $time);
      return 1;
    }
  print "no targets in drop\n"; 
  return 0;
}

sub target_drag_data_received {
  my ($widget, $context, $x, $y, $data, $info, $time) = @_;
  print "Receiving $data in trashcan\n";
  if (($data->length >= 0) && ($data->format == 8))
    {
      printf ("Received \"%s\" in trashcan\n", $data->data);
      $context->finish (1, 0, $time);
      return;
    }
  
  $context->finish (0, 0, $time);
}
  
sub label_drag_data_received {
  my ($widget, $context, $x, $y, $data, $info, $time) = @_;
  if (($data->length >= 0) && ($data->format == 8))
    {
      printf ("Received \"%s\" in label\n", $data->data);
      $context->finish (1, 0, $time);
      return;
    }
  
  $context->finish (0, 0, $time);
}

sub source_drag_data_get {
  my ($widget, $context, $data, $info, $time) = @_;
  if ($info == TARGET_ROOTWIN) {
    print ("I was dropped on the rootwin\n");
  } else {
    $data->set ($data->target, 8, "I'm Data!");
  }
}
  
#/* The following is a rather elaborate example demonstrating/testing
# * changing of the window heirarchy during a drag - in this case,
# * via a "spring-loaded" popup window.
# */
$popup_window = undef;

$popped_up = 0;
$in_popup = 0;
$popdown_timer = 0;
$popup_timer = 0;

sub popdown_cb
{
  $popdown_timer = 0;

  $popup_window->hide();
  $popped_up = 0;

  return 0;
}

sub popup_motion
{
  my ($widget, $context, $x, $y, $time) = @_;
  if (!$in_popup)
    {
      $in_popup = 1;
      if ($popdown_timer)
	{
	  print ("removed popdown\n");
	  Gtk->timeout_remove ($popdown_timer);
	  $popdown_timer = 0;
	}
    }

  return 1;
}

sub  popup_leave {
  my ($widget, $context, $time) = @_;
  if ($in_popup)
    {
      $in_popup = 0;
      if ($popdown_timer)
	{
	  print ("added popdown\n");
	  $popdown_timer = Gtk->timeout_add (500, \&popdown_cb);
	}
    }
}

sub popup_cb {
  if (!$popped_up)
    {
      if (!$popup_window)
	{
	  my ($button, $table, $i, $j);
	  
	  $popup_window = new Gtk::Window('popup');
	  $popup_window->set_position('mouse');

	  $table = new Gtk::Table (3,3, 0);

	  for ($i=0; $i<3; $i++) {
	    for ($j=0; $j<3; $j++)
	      {
		$button = new Gtk::Button ("$i,$j");
		$table->attach ($button, $i, $i+1, $j, $j+1,
				  ['expand','fill'],['expand','fill'], 0, 0);

		$button->drag_dest_set ('all', ['copy', 'move'],
			@target_table[0..1]); # no rootwin
		$button->signal_connect ("drag_motion", \&popup_motion);
		$button->signal_connect ("drag_leave", \&popup_leave);
	      }
	  }
	  $table->show_all ();
	  $popup_window->add($table);

	}
      $popup_window->show;
      $popped_up = 1;
    }

  $popdown_timer = Gtk->timeout_add (500, \&popdown_cb);
  print ("added popdown\n");

  $popup_timer = 0;

  return 0;
}

sub popsite_motion {
  my ($widget, $context, $x, $y, $time) = @_;
  if (!$popup_timer) {
    $popup_timer = Gtk->timeout_add (500, \&popup_cb);
  }
  return 1;
}

sub  popsite_leave {
  my ($widget, $context, $time) = @_;
  if ($popup_timer)
    {
      Gtk->timeout_remove ($popup_timer);
      $popup_timer = 0;
    }
}

sub source_drag_data_delete {
  my ($widget, $context, $data) = @_;
  print ("Delete the data!\n");
}
  
init Gtk;

$window = new Gtk::Window;
$window->signal_connect('destroy', sub {Gtk->main_quit});

$table = new Gtk::Table(2, 2, 0);

$window->add($table);

($drag_icon, $drag_mask) = Gtk::Gdk::Pixmap->colormap_create_from_xpm_d (
	undef, $window->get_colormap(), undef, @drag_icon_xpm);
($trashcan_open, $trashcan_open_mask) = Gtk::Gdk::Pixmap->colormap_create_from_xpm_d (
	undef, $window->get_colormap(), undef, @trashcan_open_xpm);
($trashcan_closed, $trashcan_closed_mask) = Gtk::Gdk::Pixmap->colormap_create_from_xpm_d (
	undef, $window->get_colormap(), undef, @trashcan_closed_xpm);

$label = new Gtk::Label("Drop Here\n");

$label->drag_dest_set('all', ['copy', 'move'], @target_table[0..1]); # no rootwin

$label->signal_connect("drag_data_received", \&label_drag_data_received);

$table->attach ($label, 0, 1, 0, 1, ['expand', 'fill'], ['expand', 'fill'], 0, 0);

$label = new Gtk::Label("Popup\n");

$label->drag_dest_set('all', ['copy', 'move'], @target_table[0..1]); # no rootwin

$table->attach ($label, 1, 2, 1, 2, ['expand', 'fill'], ['expand', 'fill'], 0, 0);

$label->signal_connect ("drag_motion", \&popsite_motion);
$label->signal_connect ("drag_leave", \&popsite_leave);
  
$pixmap = new Gtk::Pixmap ($trashcan_closed, $trashcan_closed_mask);
$pixmap->drag_dest_set ([], []);
$table->attach ($pixmap, 1, 2, 0, 1, ['expand', 'fill'], ['expand', 'fill'], 0, 0);

$pixmap->signal_connect ("drag_leave", \&target_drag_leave);

$pixmap->signal_connect ("drag_motion", \&target_drag_motion);

$pixmap->signal_connect ("drag_drop", \&target_drag_drop);

$pixmap->signal_connect ("drag_data_received", \&target_drag_data_received);

#  /* Drag site */

$button = new Gtk::Button ("Drag Here\n");

$button->drag_source_set (['button1_mask', 'button3_mask'], ['copy', 'move'], @target_table);
$button->drag_source_set_icon ($window->get_colormap,  $drag_icon, $drag_mask);

#$drag_icon->unref;
#$drag_mask->unref;

$table->attach ($button, 0, 1, 1, 2, ['expand', 'fill'], ['expand', 'fill'], 0, 0);

$button->signal_connect ("drag_data_get", \&source_drag_data_get);
$button->signal_connect ("drag_data_delete", \&source_drag_data_delete);

$window->show_all;

Gtk->main ();

exit(0);


