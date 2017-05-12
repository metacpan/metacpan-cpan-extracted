#!/home/markt/bin/perl -w
use strict;
no strict 'subs';
use lib '..';
use Java;

# Connect to JavaServer
my $java = new Java();

print "going to frame1\n";
# Create my Frame object
my $frame = $java->create_object("java.awt.Frame","Event Example");

# Set the size and show it
$frame->setSize(200,200);
$frame->show();

# Set up an event listener
$java->do_event($frame,"addWindowListener",\&event);

print "going to dialog\n";

my $dialog = $java->create_object("java.awt.Dialog",$frame,"Mark's Dialog");
$dialog->setSize(400,400);
print "going to dialog show\n";
$dialog->setVisible("true:b");
print "back from dialog show\n";

print "going to frame2\n";

my $frame2 = $java->create_object("java.awt.Frame","Mark Rox");
$frame2->setSize(200,200);
$frame2->show();
$java->do_event($frame2,"addWindowListener",\&event);

while(1)
{
	print "GO'ing\n";
	my $b = $java->go;
	last if (!defined $b);
}

sub event
{
	my($object,$event) = @_;
	my $val = $event->getID->get_value;
	if ($val == $java->get_field("java.awt.event.WindowEvent","WINDOW_ACTIVATED")->get_value)
	{
		print "Window Activated\n";
	}
	if ($val == $java->get_field("java.awt.event.WindowEvent","WINDOW_CLOSED")->get_value)
	{
		print "Window Closed\n";
	}
	if ($val == $java->get_field("java.awt.event.WindowEvent","WINDOW_CLOSING")->get_value)
	{
		print "Window Closing\n";
		$object->dispose;
		undef $object;
	}
	if ($val == $java->get_field("java.awt.event.WindowEvent","WINDOW_DEACTIVATED")->get_value)
	{
		print "Window Deactivated\n";
	}
	if ($val == $java->get_field("java.awt.event.WindowEvent","WINDOW_DEICONIFIED")->get_value)
	{
		print "Window Deiconified\n";
	}
	if ($val == $java->get_field("java.awt.event.WindowEvent","WINDOW_ICONIFIED")->get_value)
	{
		print "Window Iconified\n";
	}
	if ($val == $java->get_field("java.awt.event.WindowEvent","WINDOW_OPENED")->get_value)
	{
		print "Window Opened\n";
	}
}
