
require 5;
package Getopt::Janus::Tk;
# Get the program options via a GUI


@ISA = ('Getopt::Janus::SessionBase');
$VERSION = '1.03';
use strict;
use Getopt::Janus::SessionBase ();

use Getopt::Janus (); # makes sure Getopt::Janus::DEBUG is defined
BEGIN { *DEBUG = \&Getopt::Janus::DEBUG }

DEBUG and print "Revving up ", __PACKAGE__, " at debug=", DEBUG, "\n";

use Tk ();
use Carp ('confess');
require Tk::Button;
require Tk::Frame;
require Tk::Pane;
require Tk::Entry;

sub to_run_in_eval {1}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_option_values {
  my $self = shift;
  
  my $m;
  my $run_flag;
  my $run_flag_set = sub { $run_flag = 1; $m->destroy; return; };
  $m = $self->set_up_window($m, $run_flag_set);

  DEBUG and print "\n";
  Tk::MainLoop();
  DEBUG and print "\n";
  DEBUG and print '', !$run_flag_set ? "Aborting.\n" : "Now running.\n";
  
  undef $m;
  exit unless $run_flag;
  # otherwise fall thru
  return;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub set_up_window {
  my($self, $widget, $run_flag_set) = @_;

  my $m = MainWindow->new();
  $m->title( $self->{'title'} )  if  $self->{'title'};
  $m->bind('<Escape>' => [$m, 'destroy'] );
  $m->geometry('+0+0');

  $self->{'width'}  = 0;
  $self->{'height'} = 0;

  my $pane = $m->Scrolled( 'Pane',
   '-scrollbars' => 'osoe',
   '-sticky'     => 'nsew',
   '-gridded'    => 'y'
  );
  $pane->pack( '-fill' => 'both',  '-expand' => 1 );
  
  $self->make_bundles($pane, $m);
  $self->button_bar($pane, $m,
    1,   # was: !@{$self->{'options'} || []},  # whether to focus the OK button
    $run_flag_set,
  );
  $self->place_window($pane, $m);
  $m->focus;
  return $m;
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub make_bundles {
  # Iterate over the options, and for each one, make a BUNDLE of GUI things
  # (a label, some more stuff, a help button, whatever).

  my($self, $pane, $mainwindow) = @_;
  my $them = $self->{'options'} || [];
    
  foreach my $option (@$them) {
    my $method = 'make_bundle_'
     . ( $option->{'type'} || confess "Typeless option?!" );
    $self->$method($option, $pane, $mainwindow);

    # And now a little divider
    my $f = $pane->Frame(qw/  -relief ridge  -bd 1  -height 3  /);
    $f->grid( qw<  -columnspan 3  -sticky ew  > );
    $self->consider_grid_row($f);
  }
  
  return;
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub button_bar {
  my($self, $pane, $mainwindow, $whether_focus_okay, $run_flag_set) = @_;

  # A frame within which we can use pack instead of grid:
  my $button_bundle_frame = $pane->Frame();

  $button_bundle_frame->grid( qw< -columnspan 3  -sticky s > );

  my @button_pack_options = qw< -side left  -pady 9 -padx 9  >;

  my $okay;
  
  ($okay = $button_bundle_frame->Button(
    '-text'    => 'OK',
    '-command' => $run_flag_set,
  ))->pack( @button_pack_options,  );
  
  $button_bundle_frame->Button(
    '-text'    => 'Cancel',
    '-command' => [ $mainwindow => 'destroy' ],
  )->pack(  @button_pack_options );

  my $main_help_box = $self->main_help_maker( $mainwindow );
  $mainwindow->bind('<F1>' => $main_help_box );

  $button_bundle_frame->Button(
    '-text'    => 'Help',
    '-command' => $main_help_box,
  )->pack( @button_pack_options );
  
  $self->consider_grid_row( $button_bundle_frame );
  
  $okay->focus if $whether_focus_okay;

  return;
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub main_help_maker {
  my($self, $mainwindow) = @_;
  return sub {
    my $dialogbox;
    require Tk::DialogBox;
    require Tk::Text;

    {
      $dialogbox = $mainwindow->DialogBox(
        '-title'   => "Help for $$self{'title'}",
        '-buttons' => [
          'OK',
          $self->{'license'} ? ('See License') : ()
        ],
      );
      my $t = $dialogbox->add('Scrolled' => 'Text' =>
        -scrollbars => 'oe',
        -height => 22,
        -width => 80,
        -font => 'roman',  # no real need for monospace
      );
      $t->pack;
      $t->insert('@0,0', $self->_text_for_program() );
      $t->configure(qw<  -state disabled  -takefocus 1  >);
        # make it non-editable, but selectable
    }


    return unless 'See License' eq ($dialogbox->Show || '');


    {
      # They chose to see the license.  A near-repeat of the
      # previous block.
      $dialogbox = $mainwindow->DialogBox(
        '-title'   => "License for $$self{'title'}",
        '-buttons' => ['OK'],
      );
      my $t = $dialogbox->add('Scrolled' => 'Text' =>
        -scrollbars => 'oe',
        -height => 22,
        -width => 80,
        -font => 'roman',  # no real need for monospace
      );
      $t->pack;
      $t->insert('@0,0',
         $self->{'license'}->()
      );
      $t->configure(qw<  -state disabled  -takefocus 1  >);
        # Make it non-editable, but selectable
  
      $dialogbox->Show;  # Don't need the value, tho.
    }
    return;
  };
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub _text_for_program {
  my $self = $_[0];
  return join '',
    $self->long_help_message(),

    "\n",
    "Built with Perl and Getopt::Janus.\n",
    "(You are running Perl v$] for $^O",
    
    (defined(&Win32::BuildNumber) and defined &Win32::BuildNumber())
     ? (" Win32::BuildNumber \#", &Win32::BuildNumber())
    : defined($MacPerl::Version)
     ? " MacPerl v$MacPerl::Version\n"
    : (),

    (chr(65) eq 'A') ? () : " non-ASCII",
    q{).},
  ;
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub consider_grid_row {
  my $self       = shift;
  my $width      = 0;
  my $max_height = 0;
  
  DEBUG > 1 and print "Considering grid-row widgets @_\n";
  
  foreach my $widget (@_) {
    DEBUG > 1 and printf " Widget %s  is %sw x %sh (%sw x %sh)\n",
      $widget, $widget->reqwidth, $widget->reqheight,
       $widget->width || '~', $widget->height || '~';
    $width += $widget->reqwidth;
    my $this_height = $widget->reqheight;
    $max_height = $this_height if $max_height < $this_height;
  }

  $self->{'height'} += $max_height;
  $self->{'width' }  = $width if $width > $self->{'width'};
  
  DEBUG and printf "Global %sw x %sh\n", $self->{'width'}, $self->{'height'};
  
  return;
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub place_window {
  my($self, $pane, $m) = @_;
  
   # This routine's geometry guessing is potentially inaccurate, but it
   # works fine most of the time, and doesn't generate any really
   # spectacular failures even when it doesn't get things quite right.
  
  my $height = int( ($self->{'height'} || return) +  60 );
  my $width  = int( ($self->{'width' } || return) + 150 );
   # Those 60 and 160 are the fudge factor for scrollbars, for
   # the fact that frames think they're all 1x1, and so on.
   # (We could ask the frames to update, but this seems to make
   # things even worse elsewhere!)
  
  DEBUG and printf "Pane: %sw x %sh\n", $width, $height;

  my $max_w = $pane->screenwidth  - 60;
  my $max_h = $pane->screenheight - 60;
  $width  = $max_w if $width  > $max_w;
  $height = $max_h if $height > $max_h;

  $pane->configure( '-width' => $width  , '-height' => $height );
  return;
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub common_make_bundle { # operates on an option
  my($self, $option, $pane, $mainwindow, $new) = @_;

  DEBUG > 4 and print "self $self, option $option, mw $mainwindow, new $new\n";

  if( defined( $option->{'short'} ) and $option->{'action'} ) {
    my $event_spec = '<Alt-' . $option->{'short'} . '>';
    DEBUG > 1 and print "Binding $event_spec to new object $new\'s",
      " event $$option{'action'}\n";
    $mainwindow->bind( $event_spec => $option->{'action'} );
    $option->{'shortcut_key'} = $event_spec;
  }

  my @widgets = (
    $pane-> Label(
      '-text' => $self->_option_title($option) . ": ",
      -takefocus => 0,
    ),
    $new,
    $pane->Button(
      '-text' => '?',
      '-pady' => 0,
      '-command' => $self->option_help_maker($option, $pane, $mainwindow),
    ),
  );

  DEBUG > 2 and print "Gridding up widgets @widgets\n";

  @widgets and $widgets[0]->grid( @widgets[1 .. $#widgets],
     -padx => 2,
#    -padx => 5, -pady => 5,
  );
  
  $self->consider_grid_row(@widgets);
  
  return;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub make_bundle_string     { # operates on an option
  my($self, $option, $pane, $mainwindow) = @_;
  my $widget = $mainwindow->Entry( '-width' => 15, '-textvariable'
    => $option->{'slot'} || confess "No slot in @{[%$option]})!?"
  );
  $option->{'action'} = sub {
    $widget->focus;
    $widget->selectionRange('0', 'end');
    $widget->xviewMoveto(1);
    $widget->icursor('end');
    return;
  };

  DEBUG and print "Calling _common_make_bundle\n";
  return $self->common_make_bundle( $option, $pane, $mainwindow, $widget );
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub make_bundle_yes_no   { # operates on an option
  my($self, $option, $pane, $mainwindow) = @_;

  require Tk::Checkbutton;
  my $widget = $mainwindow->Checkbutton(
    #-text     => 'Hi there',
    -variable  => ($option->{'slot'} || confess "No slot in @{[%$option]})!?"),
    -relief    => 'flat'
  );

  #$option->{'action'} = sub { $widget->focus; $widget->invoke; return };
  $option->{'action'} = sub {
    $widget->focus;
    $widget->invoke;
    return;
  };
  DEBUG and print "Calling _common_make_bundle\n";
  return $self->common_make_bundle( $option, $pane, $mainwindow, $widget );
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub make_bundle_choose   { # operates on an option
  my($self, $option, $pane, $mainwindow) = @_;
  require Tk::BrowseEntry;
  my $widget = $mainwindow->BrowseEntry(
    #-text     => 'Hi there',
    #-relief   => 'flat',
    -variable  => ($option->{'slot'} || confess "No slot in @{[%$option]})!?"),
    -state     => 'readonly',
    -choices   => $option->{'from'},
  );
  
  if( $widget->can('space') ) {
    $option->{'action'} = [ $widget => 'space' ];
  } else {
    DEBUG and print "BrowseEntry widget $widget can't do 'space'.\n";
  }
  
  DEBUG and print "Calling _common_make_bundle\n";
  return $self->common_make_bundle( $option, $pane, $mainwindow, $widget );
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub make_bundle_new_file { # operates on an option
  my($self, $option, $pane, $mainwindow) = @_;
  my $slot = $option->{'slot'} || confess "No slot in @{[%$option]})!?";
  my $frame = $mainwindow->Frame;
  my $entry = $frame->Entry(  '-width' => 15, '-textvariable' => $slot );

  my @box_arguments = (
    '-title' => "Select for output: " . $self->_option_title($option),
  );
  if(defined $$slot and $$slot =~ m/\.([\+A-Za-z0-9]{1,6})$/s ) {
    push @box_arguments, '-filetypes' => [
      ["$1 Files"  => ".$1"],
      ['All Files' => '*'  ],
    ];
  }

  my $button = $frame->Button(
    '-text'    => '>...', # "To..."
    '-command' => sub {
      my $new = $mainwindow->getSaveFile(@box_arguments);
      $$slot = $new if defined $new;
      $entry->xviewMoveto(1) if defined $$slot; # make the end visible
      1;
    },
  );

  $option->{'action'} = [$button => 'focus'];

  $button->grid($entry);  # laying them both out in this frame
  return $self->common_make_bundle( $option, $pane, $mainwindow, $frame );
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub make_bundle_file     { # operates on an option
  my($self, $option, $pane, $mainwindow) = @_;
  my $slot = $option->{'slot'} || confess "No slot in @{[%$option]})!?";
  my $frame = $mainwindow->Frame;
  my $entry = $frame->Entry(  '-width' => 15, '-textvariable' => $slot );

  my @box_arguments = (
    '-title' => "Select input: " . $self->_option_title($option),
  );
  if(defined $$slot and $$slot =~ m/\.([\+A-Za-z0-9]{1,6})$/s ) {
    push @box_arguments, '-filetypes' => [
      ["$1 Files"  => ".$1"],
      ['All Files' => '*'  ],
    ];
  }

  my $button = $frame->Button(
     '-text'    => '<...',  # "From..."
     '-command' => sub {
       my $new = $mainwindow->getOpenFile(@box_arguments);
       $$slot = $new if defined $new;
       $entry->xviewMoveto(1) if defined $$slot; # make the end visible
       1;
     },
  );
  $option->{'action'} = [$button => 'focus'];

  $button->grid($entry);  # laying them both out in this frame
  return $self->common_make_bundle( $option, $pane, $mainwindow, $frame );
}

#==========================================================================

sub option_help_maker { # operates on an option
  my($self, $option, $pane, $mainwindow) = @_;
  my $program_title = $self->{'title'};

  return sub {
    require Tk::DialogBox;
    require Tk::Text;

    my $dialogbox = $mainwindow->DialogBox(
      '-title' => "Help for: $$self{'title'}: " .
        $self->_option_title($option),
      '-buttons' => ['OK'],
    );
    my $t = $dialogbox->add('Scrolled' => 'Text' =>
      -scrollbars => 'oe',
      -height => 10,
      -width => 60,
      -font => 'roman',  # no real need for monospace
    );
    $t->pack;
    $t->insert('@0,0', $self->_text_describing_option($option) );
    $t->configure(qw<-state disabled -takefocus 1>);
      # make it non-editable, but selectable
    
    $dialogbox->Show;
    return;
  };
}

sub _text_describing_option {  # operates on an option
  my($self, $option) = @_;
  return join '',

    "Option name: \"", $self->_option_title($option),
    "\"\n\n",

    defined( $option->{'description'} )
      ? "$$option{'description'}\n\n" : (),

    "Type: $$option{'type'}\n",

    defined( $option->{'short'} )
      ? "Short command-line form: -$$option{'short'}\n" : (),

    defined( $option->{'long'} )
      ? "Long command-line form: --$$option{'long'}\n" : (),

    defined( $option->{'shortcut_key'} )
      ? "Shortcut key: $$option{'shortcut_key'}\n" : (),
  ;
}

sub _option_title { # operates on an option
  my($self, $option) = @_;
  return
     defined( $option->{'title'} ) ? $option->{'title'}
   : defined( $option->{'long'}  ) ? "--$$option{'long'}"
   : defined( $option->{'short'} ) ? "-$$option{'short'}"
   : "[???]" # should be unreachable
}

#==========================================================================

sub review_result_screen {
  my($self, $items) = @_;
  return unless @$items;
  DEBUG > 2 and print "Making a new window for ", scalar(@$items), " items\n";
  require Tk::Checkbutton;

  my $mainwindow = MainWindow->new;
  $mainwindow->title("Reviewing Output of $$self{'title'}");
  my $pane;
  if(@$items < 4) {
    $pane = $mainwindow;
  } else {
    $pane = $mainwindow->Scrolled( 'Pane',
     '-scrollbars' => 'osoe',
     '-sticky'     => 'nsew',
     #'-gridded'    => 'y'
    );
    $pane->pack( '-fill' => 'both',  '-expand' => 1 );
  }
  
  foreach my $i (@$items) {
    my($f,$d) = @$i;
    next unless defined $f or defined $d;

    require Tk::Menubutton;
    my $mb = $pane->Menubutton(
       qw/ -relief raised -takefocus 1 -indicatoron 1 -direction right/,
       -text => $f,
    );

    $mb->configure( -menu => $mb->menu(qw/-tearoff 0/) );

    defined $f and $self->can_open_files and $mb->command(
      -label => "Run this file",
      -command =>  sub { $self->open_file($f) },
    );

    defined $f and $self->can_open_directories and $mb->command(
      -label => "Open this directory",
      -command =>  sub { $self->open_directory($d) },
    );
    defined $f and $self->can_open_files and $mb->command(
      -label => "Copy this filespec", -command =>  sub {
        $mainwindow->clipboardClear;
        $mainwindow->clipboardAppend( '--', $f );
      },
    );
    $mb->pack;
  }

  # Just a divider:
  $pane->Frame(qw/ -relief ridge -bd 1 -height 3 /)->pack('-fill' => 'x' );

  # A frame for the button(s) at the bottom:
  my $button_bundle_frame = $pane->Frame();
  $button_bundle_frame->pack;
  
  my $done_button;
  ($done_button = $button_bundle_frame->Button(
    '-text'    => 'Done',
    '-command' => [ $mainwindow => 'destroy' ],
  ))->pack( qw< -side left  -pady 9 -padx 9  > );
  $done_button->focus;

  $mainwindow->bind('<Escape>' => [$mainwindow, 'destroy'] );

  DEBUG and print "\n";
  Tk::MainLoop();
  DEBUG and print "\n";
  return;
}

#==========================================================================

sub report_run_error {
  my($self, $error_text) = @_;
  $error_text ||= "Unknown error!?";

  DEBUG and print "Reporting error $@\n";

  my $m = MainWindow->new;
  $m->title("Error!");
  $m->label("An error occurred in the program:\n");
  
  my $t = $m->Scrolled( 'Text',
    -scrollbars => 'oe',
    -height => 10,
    -width  => 60,
  );
  $t->pack;
  $t->insert('@0,0', $error_text);
  $t->configure(qw<  -state disabled   -takefocus 1  >);
    # make it non-editable, but selectable
  
  my $button = $m->Button(
    '-text'    => 'Abort the Program',
    '-command' => [$m, 'destroy'],
  );
  $m->bind('<Escape>' => [$m, 'destroy'] );

  $button->pack;
  $button->focus;

  $m->geometry('+20+20');

  DEBUG and print "\n";
  Tk::MainLoop();
  DEBUG and print "\n";

  return;
}

#==========================================================================

__END__

