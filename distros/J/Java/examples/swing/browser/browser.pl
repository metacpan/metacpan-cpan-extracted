#!/home/markt/usr/local/Linux/bin/perl

##
# A Krappy Browser
##

use strict;
no strict 'subs';
use vars qw($java $frame);
use lib qw(../../..);
use Java;

# Set up some convenience stuff
my $awt = "java.awt";
my $swing = "javax.swing";
my @menus;

# Create connection to JavaServer
$java = new Java();

do 'menu_bar.pl';

# Used by 'Back' button
my @previous_pages;
my $current_page = "http://www.zzo.com/Java/getit.html";
push @previous_pages, $current_page;

# Create the window and a Panel
$frame = $java->create_object("$swing.JFrame","I'll Call Him, Mini-Browser");

#
# Get default and 'hand' cursor to change cursor when ya move it over
#	a link
#
my $default_cursor = $frame->getCursor;
my $hand_cursor = $java->create_object("java.awt.Cursor",$java->get_field("java.awt.Cursor","HAND_CURSOR")->get_value);

##
# Add menus
##
push @menus, &file_menu, &edit_menu;
&menu_bar(@menus);
$frame->setJMenuBar(&menu_bar(@menus));

###
# Make some Buttons 
##
my $back_button = $java->create_object("$swing.JButton","Back");
$java->do_event($back_button,"addActionListener",\&back_button);
my $reload_button = $java->create_object("$swing.JButton","Reload");
$java->do_event($reload_button,"addActionListener",\&reload_button);

##
# Make 2 panels
#	One is main panel to display URL & other has Location text field
##
##
my $top_panel = $java->create_object("$swing.JPanel");
my $button_panel = $java->create_object("$swing.JPanel");
my $text_panel = $java->create_object("$swing.JPanel");
my $main_panel = $java->create_object("$swing.JEditorPane",$current_page);
$main_panel->setEditable("false:b");

#
# Listen for hyperlink events to change cursor & to jump to new location
#	if they press it
#
$java->do_event($main_panel,"addHyperlinkListener",\&hyperlink_listener);

# Toss main panel into scroll pane
my $scroll_pane = $java->create_object("$swing.JScrollPane",$main_panel);

# Location Text field
my $loc_field = $java->create_object("$swing.JTextField",$current_page,30);
$loc_field->setToolTipText("Type in URL here!");
my $label = $java->create_object("$swing.JLabel","Location:");
$label->setLabelFor($loc_field);

$text_panel->add($label);
$text_panel->add($loc_field);
$button_panel->add($back_button);
$button_panel->add($reload_button);
$top_panel->add($button_panel,"North");
$top_panel->add($text_panel,"Center");
$java->do_event($loc_field,"addActionListener",\&loc_field_listener);


# Add the panel to the 'Center' of the Content Pane
$frame->getContentPane->add($top_panel,"North");
# $frame->getContentPane->add($main_panel,"Center");
$frame->getContentPane->add($scroll_pane,"Center");

$frame->setSize(900,900);
$frame->show;
$frame->setVisible("true:b");

# This is my exciting event loop!
 my $cont = 1;
 while($cont)
 {
	 $cont = $java->go;
 }
$frame->dispose;


sub loc_field_listener
{
	my($obj,$event) = @_;
	push @previous_pages, $current_page;
	my $url = $loc_field->getText->get_value;
	# Tell Java to get it & render it!
	$url = "http://".$url if ($url !~ /^http/i);
	$main_panel->setPage($url);
	$current_page = $url;
	1;
}

sub hyperlink_listener
{
	my($obj,$event) = @_;
	my $type = $event->getEventType->get_value;
	#print "type is $type\n";

	# They pressed it
	if ($type eq 'ACTIVATED')
	{
		push @previous_pages, $loc_field->getText->get_value;
		my $url = $event->getURL;
		$current_page = $url->get_value;
		$loc_field->setText($current_page);
		$main_panel->setPage($url);
	}

	# They're over it!
	if ($type eq 'ENTERED')
	{
		$frame->setCursor($hand_cursor);
	}

	# They ain't there anymore!
	if ($type eq 'EXITED')
	{
		$frame->setCursor($default_cursor);
	}

	1;
}

sub back_button
{
	# They wanna go back...
	my($obj,$event) = @_;

	# Get whatever's on the top of the @previous_pages array
	# & roll it...
	my $page;
	$page = pop @previous_pages if (@previous_pages > 1);
	if ($page)
	{
		$current_page = $page;
		$current_page = "http://".$current_page if ($current_page !~ /^http/i);
		$loc_field->setText($current_page);
		$main_panel->setPage($current_page);
	}

	1;
}

sub reload_button
{
	# They wanna go reload...
	my($obj,$event) = @_;

	$main_panel->setPage($current_page);

	1;
}
