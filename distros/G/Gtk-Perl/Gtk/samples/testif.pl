#!/usr/bin/perl -w

#TITLE: ItemFactory
#REQUIRES: Gtk

use Gtk;

init Gtk;

$win = new Gtk::Window;
$accel = new Gtk::AccelGroup;
$accel->attach($win);
$factory = new Gtk::ItemFactory('Gtk::MenuBar', '<main>', $accel);

$factory->create_items({ path	     =>  '/_File',
			 type	     =>  '<Branch>',
		       },
		       { path	     =>  '/_File/tearoff1',
			 type	     =>  '<Tearoff>',
		       },
		       { path	     =>  '/_File/_Hello',
			 accelerator =>  '<control>H',
			 action      =>  2,
			 callback    =>  [sub {
					      my ($widget, $action, @args) = @_;
					      print "Hello world! action=$action, args=(@args)\n"
					  }, 17, 42],
		       },
		       { path	     =>  '/_File/E_xit',
			 accelerator =>  '<control>X',
			 callback    =>  sub {Gtk->exit(0)}
		       });

sub foo_callback {
    my ($widget, $action, @args) = @_;
    print "Foo! action=$action, args=(@args)\n";
}

$factory->create_item(['/_Menu/tearoff1', undef, 0, '<Tearoff>']);
$factory->create_item(['/_Menu/foo _1', undef, 1, undef], \&foo_callback, 1, 2, 3);
$factory->create_item(['/_Menu/foo _2', undef, 2, undef, \&foo_callback]);

$factory->create_items({ path	     => '/_Help',
			 type	     => '<LastBranch>',
		       },
		       { path	     =>  '/_Help/tearoff1',
			 type	     =>  '<Tearoff>',
		       },
		       ['/_Help/_About', '<control>A', 0, undef, sub {print "Just a test\n"}]);

$menubar = $factory->get_widget('<main>');
$menubar->show;
$win->add($menubar);
$win->show;
$win->signal_connect('delete_event', sub {Gtk->exit(0)});
main Gtk;

