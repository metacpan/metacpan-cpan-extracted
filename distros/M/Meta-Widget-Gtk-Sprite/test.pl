# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use Gtk;
use Gnome;
init Gnome "test.pl";


#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use lib ".";
use Meta::Widget::Gtk::Sprite;

my $mw = new Gtk::Window( "toplevel" );
my($canvas) = Gnome::Canvas->new() ;
$mw->add($canvas );
$canvas->show;
my $croot = $canvas->root;
my $sprites = new Meta::Widget::Gtk::Sprite($croot);
my $p1 = $sprites->create("./player1.xpm", 100, 0);
$sprites->slide_to_time($p1,5000, 100, 100);
my $p2 = $sprites->create("./player2.xpm", 0, 0);
$sprites->slide_to_speed($p2,10, 100, 100);
$sprites->set_collision_handler(\&Bang);
$sprites->show($p1);
$sprites->show($p2);
$mw->show;
		Gtk->main;
sub Bang
	{
		print "Bang!\n";
		exit;
	}

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

