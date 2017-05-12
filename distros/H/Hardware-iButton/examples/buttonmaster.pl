#!/usr/bin/perl -w

use Gtk;
use Hardware::iButton::Connection;

Gtk->init();

# top level window: list of iButtons, buttons on bottom: 
# 'scan', 'about', 'quit'

{
    #my $mw = new Gtk::Widget
    #  "GtkWindow",
    #  GtkWindow::type => -toplevel,
    #  GtkWindow::title => "iButton Master",
    #  GtkContainer::border_width => 10,
    #  ;
    my $mw = Gtk::Widget->new("GtkWindow",
			      -type => 'toplevel',
			      -title => 'iButton Master',
			      -border_width => 2);
    $mw->set_usize(275, 150);
    $mw->signal_connect("destroy", sub { Gtk->main_quit; });
    $mw->signal_connect("delete_event", sub {Gtk->main_quit});
    my $vbox = Gtk::VBox->new(0,0);

    my(@titles) = ("Serial Number", "Device Type", "Family Code");
    $clist = Gtk::CList->new_with_titles(@titles);
    {
	my $style = $mw->style();
	my $font = $style->font();
	my $width = Gtk::Gdk::Font::string_width($font, "Serial Number");
	#print "width is $width\n";
	$width = Gtk::Gdk::Font::string_width($font, "cccccccccccc");
	$clist->set_column_width(0, $width);
    }
    #$clist->set_column_width(0, 80);
    $clist->set_column_width(1, 75);
    $clist->set_column_width(2, 70);
    $clist->set_selection_mode(-single); # would like to use -browse here, but
    # then it crashes..
#    $clist->set_policy(-automatic, -automatic);
    # we could catch the GDK_2BUTTON_PRESS event to get double-clicks
#    $clist->signal_connect("eventfoo", 
#			   sub {
#			       my($stufffoo) = @_;
#			       print "event: foo\n";
#			       });
    $clist->signal_connect("select_row", 
#			   sub {
#			       my($list, $row, $col, $event) = @_;
#			       print "row $row selected\n";
#			       }
			   \&handle_select,
			  );
#    $clist->signal_connect("button_press_event", \&press);
    $clist->signal_connect("click_column", \&sortby);
    $clist->show(); 
    $vbox->pack_start($clist, 1, 1, 0);

    $status = Gtk::Statusbar->new();
    #$status->set_usize(100, -1); # -1 means leave height alone
    $status->show(); 
    $vbox->pack_start($status, 0, 0, 0);
    
    my $hbox = Gtk::HBox->new(0,0);
    $hbox->show();
    $vbox->pack_start($hbox, 0, 0, 2);

    my $quit_button = Gtk::Widget->new("GtkButton",
				       -label => "Quit",
				       -clicked => sub { $mw->destroy; },
				       -visible => 1);
    $quit_button->show();
    $hbox->pack_start($quit_button, 1, 0, 2);
    my $about_button = Gtk::Widget->new("GtkButton",
					-label => "About",
				       -clicked => \&do_about,
				       -visible => 1);
    $about_button->show();
    $hbox->pack_start($about_button, 1, 0, 2);
    $scan_button = Gtk::Widget->new("GtkButton",
				    -label => "Scan",
				    -clicked => \&do_scan,
				    -visible => 1);
    $scan_button->show();
    $hbox->pack_start($scan_button, 1, 0, 2);
    $vbox->show();
    $mw->add($vbox);
    $mw->show();
}

sub clear_ref {
    my($widget, $ref) = @_;
    $$ref = undef;
    0;
}

my $aboutbox;
sub do_about {
    # put up an about box
    if ($aboutbox) {
	print "hey, cut it out\n";
	return; # don't do it twice
    }
    $aboutbox = Gtk::Widget->new("GtkWindow",
				 -type => 'toplevel', # toplevel, dialog, popup
				 # popup: no decorations, at 0,0
				 # dialog: decorations, at 0,0
				 # toplevel: decorations, normal placement
				 -title => 'about',
				);
    my $vbox = Gtk::VBox->new(0,0);
    my $text = Gtk::Label->new("iButton Master\nby\nBrian Warner\n<warner\@lothar.com>");
    #$text->border_width(5); # labels can't do this
    $text->show();
    $vbox->pack_start($text, 1, 1, 0);
    my $button = Gtk::Widget->new("GtkButton",
				  -label => "Dismiss",
				  -visible => 1,
				  -border_width => 2,
				 );
    # when the box gets destroyed, clear the $aboutbox variable so that we
    # know to rebuild it next time
    $aboutbox->signal_connect("destroy", \&clear_ref, \$aboutbox);
    # when the button gets hit, tell $aboutbox to destroy itself
    $button->signal_connect("clicked", sub {$aboutbox->destroy});
				  
    $button->show();
    $vbox->pack_start($button, 1, 1, 2);
    $vbox->show();
    $aboutbox->add($vbox);
    $aboutbox->show();
}
				      

$scan_context = $status->get_context_id("scan context");

sub do_scan {
    $status->push($scan_context, "scanning.."); # this doesn't quite work..
    # update screen
    while(Gtk::Gdk->events_pending) {
	Gtk->main_iteration();
    }
    @buttons = $c->scan();
    $status->pop($scan_context);
    sortby("dummy", $sort_order);
}

#my(@buttons) = ({ serial => "000001CE65EF",
#		  model => "DS1996",
#		  family => "1C",
#		 },
#		{ serial => "000003FF8902", 
#		  model => "DS1920",
#		  family => "04",
#		},
#		{ serial => "000235AA65EF", 
#		  model => "Javabutton", 
#		  family => "14",
#		},
#	       );

$sort_order = 0;

sub sortby {
    my($list, $col) = @_;
    # $col was clicked. Rearrange the rows to sort by that column.
    $sort_order = $col;
    my(@sorted);
    if ($sort_order == 0) {
	# serial number
	@sorted = sort {$a->serial cmp $b->serial} @buttons;
    } elsif ($sort_order == 1) {
	# model
	@sorted = sort {$a->model cmp $b->model} @buttons;
    } elsif ($sort_order == 2) {
	# family code
	@sorted = sort {$a->family cmp $b->family} @buttons;
    } else {
	# weirdo
	@sorted = @buttons;
    }

    # remove everything from the list
    $clist->clear();

    # add in the new buttons from the list
    foreach $i (0 .. $#sorted) {
	$clist->append($sorted[$i]->serial,
		       $sorted[$i]->model,
		       $sorted[$i]->family);
	$clist->set_row_data($i, $sorted[$i]);
    }

}

use Data::Dumper;

sub press {
    my($widget, $event, $data) = @_;
    print "press:\n";
    print Dumper($event);
    my($row,$col)=$widget->get_selection_info($event->{'x'},$event->{'y'});
    # drat, this call isn't implemented (it is commented out in Gtk-0.2_03,
    # at the end of GtkCList.xs, probably because it involves returning two
    # return values). We have to do it ourselves.
    
    # I'm not sure we can implement it ourselves. We need info about the
    # which rows are currently being selected

    # what we would do:
    return unless $event->{'type'} eq '2button_press' 
      and $event->{'button'} == 1;
    inspect($widget->get_row_data($row));
}

sub handle_select {
    my($list, $row, $col, $event) = @_;
#    unless ($event->{'type'} eq '2button_press') {
#	print "ignored\n";
#	return;
#    }
    my $serial = $list->get_row_data($row);
    inspect($serial);
}

sub inspect {
    my($button) = @_;
    my $serial = $button->serial;
    # if there isn't already one up, bring up a box to inspect this ibutton
#    print "inspect $serial\n";
#    print "event: $event\n";
#    print "event: ", Dumper($event),"\n";
    if ($inspectors{$serial}) {
#	print "already there\n";
	return;
    }
    my $in = Gtk::Widget->new("GtkWindow",
			      -type => 'toplevel',
			      -title => "iButton inspector for $serial",
			     );
    $inspectors{$serial} = $in;
    $in->signal_connect("destroy", sub {undef($inspectors{$serial})});
    $in->signal_connect("delete_event", sub {undef($inspectors{$serial})});
    $in->show;
    # top section has ID, family code, model, CRC
    # sections proceed downwards from generic to specific
    # bottom section has buttons, 'read', 'write', 'dismiss'
    my $v1 = Gtk::VBox->new(0,0);
    $in->add($v1);
#    $v1->show;
    my(@bits) = ("Serial Number", uc($serial),
		 "Family Code", uc($button->family),
		 "CRC", uc($button->crc),
		 "Model", $button->model);
    while (@bits) {
	my $b = Gtk::HBox->new(0,0);
	$b->pack_start(Gtk::Label->new(shift(@bits)),0,0,2);
	my $e = Gtk::Entry->new;
	$e->set_editable(0);
	$e->set_text(shift(@bits));
	$b->pack_end($e,0,0,0);
#	$b->show_all;
	$v1->pack_start($b, 0, 1, 2);
    }

    # add memory editor
    if ($button->{'memsize'}) {
	# for now, consider NVRAM read/write and EPROM/EEPROM read-only
	my $size = $button->{'memsize'};
	my $h2 = Gtk::HBox->new(0,0);
	# clist on left with addr,data
	# "read", "write" buttons on right
	my $c = Gtk::CList->new_with_titles("Address", "Data");
	# data cells should be entries that can be active
	$c->set_column_width(0, 50);
	$c->set_column_width(1, 40);
	my $left = $size;
	my $start = 0;
	while ($left > 0) {
	    my $data = $button->read_memory($start, ($left < 256 ? $left : 256));
	    while(length($data)) {
		my $char = substr($data, 0, 1);
		$c->append($start, unpack("H*", $char));
		substr($data, 0, 1) = "";
		$start++; $left--;
	    }
	}
	$h2->pack_start($c, 1,1,2);
	my $v2 = Gtk::VBox->new(0,0);
	my $rb = Gtk::Widget->new("GtkButton",
				  -label => "Read",
				  # disabled?
				  );
	my $wb = Gtk::Widget->new("GtkButton",
				  -label => "Write",
				  );
	$v2->pack_start($rb,0,0,2);
	$v2->pack_end($wb,0,0,2);
	$h2->pack_end($v2,0,0,0);
	$v1->pack_start($h2,1,1,2);
    }

    # temperature conversion
    if ($button->{'specialfuncs'} eq "thermometer") {
	my $h2 = Gtk::HBox->new(0,0);
	# Celsius: <number>  Farenheit: <number>  [measure]
	my $lc = Gtk::Label->new('Celsius:');
	$h2->pack_start($lc, 1, 1, 2);
	my $ec = Gtk::Entry->new;
	$ec->set_editable(0);
	$ec->set_text("???");
	$ec->set_usize(40,0);
	$h2->pack_start($ec, 1, 1, 2);
	my $lf = Gtk::Label->new('Fahrenheit:');
	$h2->pack_start($lf, 1, 1, 2);
	my $ef = Gtk::Entry->new;
	$ef->set_editable(0);
	$ef->set_text("???");
	$ef->set_usize(40,0);
	$h2->pack_start($ef, 1, 1, 2);
	my $cvt = Gtk::Widget->new("GtkButton",
				   -label => "Measure",
				   -clicked => sub {
				       my $temp = $button->read_temperature_hires();
				       $ec->set_text(sprintf('%3.2f',$temp));
				       $ef->set_text(sprintf('%3.2f',$temp*9/5 +32));
				   },
				   );
	$h2->pack_start($cvt, 1, 1, 2);
	$v1->pack_start($h2, 0, 1, 2);
#	$h2->show_all;
    }


    # bottom buttons
    my $h1 = Gtk::HBox->new(0,0);
#    $h1->show;
    $v1->pack_end($h1, 0, 0, 2);
    my $d = Gtk::Widget->new("GtkButton",
			     -label => "Dismiss",
			     -clicked => sub {$in->destroy},
			     -visible => 1);
    $h1->pack_end($d, 0, 0, 2);
#    $d->show;
    $in->show_all;
}

sub yar {
    print "yes\n";
}

$c = new Hardware::iButton::Connection "/dev/ttyS8" or die;
$s = $c->reset();
print "reset returned $s\n";

Gtk->main();


__END__

notes:

there are several different ways to create any widget. The most generic is
to use Gtk::Widget->new with the type of widget as the first arg. This lets
you set arbitrary parameters at the same time.

  $w = Gtk::Widget->new("GtkWindow",
			-type => 'toplevel',
			-title => 'pane',
			-border_width => 5,
		       );
  # or
$w = new Gtk::Widget "GtkWindow",
  GtkWindow::type => '-toplevel',
  GtkWindow::title => 'pane',
  GtkContainer::border_width => 5;

You can also use a type-specific constructor, but you're limited as to the
options you can set with the same call, and will have to go back later and
set the other options. There are some options that you just can't set in the
Gtk::Widget->new() call.

$w = Gtk::Window->new('toplevel');
$w = new Gtk::Window 'toplevel';

$w->border_width(5);
$w->title('pane');
$w->set_usize(100,200);

widgets default to not being shown. You have to call $widget->show() on just
about everything.

the signal model is more of a broadcast than NextStep's directed messages.
When a button gets clicked, it emits a yelp of "clicked!", and you have to
attach a handler to that button's click signal to hear it. To connect signals
to other widgets (say, the "dismiss" button getting clicked should tell the
about box to get destroyed), the easiest way is to use an anonymous subref:

 $dismiss_button->signal_connect("clicked", sub {$aboutbox->destroy});

You can give a third argument to signal_connect, and it will be passed to
the sub. The sub gets a first arg of the widget emitting the signal.

use signal_connect_object() to send signals to other objects. Each widget+sig
combination has a function (called a Signal Function), like 
gtk_button_clicked(obj), that causes the
given obj to be clicked (causing it to broadcast the 'clicked' signal).
signal_connect_object(widget1, "signal1", signal2func, widget2) means that
when widget1 sends out the signal1 signal, make widget2 send out signal2.
So you'd do something like
 s_c_o(button, "clicked", window, "delete");
and then clicking the button would delete the window

the objc binding looks quite nice. see obgtkObject.h for signal connection
details. ret_handler_id is an int* you can pass to get back the handler
id (the return code from signal_connect_somethingsomething), since the connect
method just returns 'self'.

to make a widget clean up when it gets destroyed, attach a signal handler to
it's 'destroy' signal to free/close stuff.

to make sure a widget doesn't appear multiple times, save the main ref to the
widget in a global. Add a destroy handler that undef's that global. When asked
to construct the widget, return right away if the global is already set.
A useful routine is:
 sub clear_ref { my($widget, $ref) = @_; $$ref = undef; 0; }
then:
 sub make_widget {
     return if $widgetref;
     # build widget, store in $widgetref
     $widgetref->signal_connect("destroy", \&clear_ref, \$widgetref);
 }

to pack something in a container:
 for hboxes and vboxes:
 $box = Gtk::HBox->new($homogeneousp, $spacing);
   $homogeneousp: each content box is the same size in the one dimension of box
   $spacing: added between content boxes
 $box->pack_start($thing, $expandp, $fillp, $padding);
  there are contents ($thing), content boxes, and the container
 expandp: 0: container shrinks to fit the content boxes, which shrink to fit
             the contents
          1: content boxes expand to fill the container's natural? size
 fillp: only matters if $expandp
        1: contents expand to fit the content boxes
        0: contents remain same size: space is left in content boxes
 padding: blank space added to both sides of each content box?




