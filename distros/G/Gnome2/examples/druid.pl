#!/usr/bin/perl -w
#
# $Id$
#

use Gnome2;
use Cwd;

use constant TRUE => 1;
use constant FALSE => 0;

$page_one_text = 
"This is a simple test of the GnomeDruid.  If this had been an actual emergency, the attention signal you just heard would've been followed by sports, fashion, entertainment, and other critical information.  Remember, this is only a test.";

$end_page_text = 
"Thank you for joining us, and thank you for reading this banal text.  I'm sorry it's so boring, but it's just filler, after all.";


# this is intentionally incorrect --- spaces are not allowed in app_name,
# because space isn't allowed in GConf keys.  this proves that the checking
# works, and keeps from polluting the GConf database with crap from test apps.
# it does, however, mean that the program will spit out lots of GConf-CRITICAL
# warnings, and present the user with a warning that the app couldn't 
# initialize properly. but this is a test, and we want to see things like that.
#Gnome2::Program->init ('Druid Test', '1.0beta');
###Gnome2::Program->init ('Druid Test', '1.0beta', 'libgnomeui');
Gnome2::Program->init ('Druid Test', '1.0beta', 'libgnomeui',
                       show_crash_dialog => FALSE,
		       app_libdir => cwd);

print "app-libdir ".(Gnome2::Program->get_program->get ('app_libdir'))."\n";

#use Data::Dumper;
#print Dumper([ Gnome2::Program->get_program->list_properties ]);

($druid, $window) = Gnome2::Druid->new_with_window ("Test Druid", undef, TRUE);

$druid->finish->set_label ("_Finish");
$druid->finish->signal_connect (clicked => sub { Gtk2->main_quit ; 1 });

$druid_page = Gnome2::DruidPageEdge->new_with_vals ('start', FALSE,
						   "Welcome",
						   $page_one_text,
						   undef,
						   undef,
						   undef);
$druid->append_page ($druid_page);


$druid_page = Gnome2::DruidPageStandard->new_with_vals ("Page Two", undef, undef);
$druid->append_page ($druid_page);
$druid_page->append_item ("Test _one:", Gtk2::Entry->new, "Longer information here");
$druid_page->append_item ("Test _two:", Gnome2::Entry->new ('fred'), "Longer information here");
$druid_page->append_item ("Test t_hree:", Gnome2::FileEntry->new ('barney', 'wilma'), "Longer information here");
$druid_page->append_item ("Test fou_r:", Gnome2::DateEdit->new (time, TRUE, FALSE), "Longer information here");

 
$druid_page = Gnome2::DruidPageStandard->new_with_vals ("Another", undef, undef);
$druid->append_page ($druid_page);

$druid_page->append_item ("For more information:", Gnome2::HRef->new ('http://gtk2-perl.sourceforge.net', 'the gtk2-perl homepage'), "click on it.  you know you want to.");

$button = Gtk2::Button->new ('play a sound');
$button->signal_connect (clicked => sub {
		Gnome2::Sound->play ('/usr/share/sounds/info.wav');
		1; } );
$druid_page->append_item ("test gnome_sound_play / Gnome2::Sound->play", $button, "sample filename is hard-coded");


$button = Gtk2::Button->new ("About");
# everything after authors may default on Gnome2::About->new.
$button->signal_connect (clicked => sub { Gnome2::About->new ("Druid Test", "0.2", "(c) 2003 by muppet and the Gnome authors whose example he ported", "decreasingly simple example of using a Gnome2::Druid and other widgets", ['muppet', 'Gnome authors'])->show; 1 });
$druid_page->append_item ("test gnome_sound_play / Gnome2::Sound->play", $button, "sample filename is hard-coded");


$druid_page = Gnome2::DruidPageEdge->new_with_vals ('finish', FALSE,
						   "Goodbye",
						   $end_page_text,
						   undef,
						   undef,
						   undef);
$druid->append_page ($druid_page);

$window->show_all;

$window->signal_connect (destroy => sub { Gtk2->main_quit; 1 });

Gtk2->main;
