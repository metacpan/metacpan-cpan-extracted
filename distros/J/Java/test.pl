# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

my $ok = 0;
BEGIN { $| = 1; print "1..33\n"; }
END {print "not ok $ok - is JavaServer on localhost running?\nHave you ran 'java_server_install.pl' yet?\nJavaServer must be running for these tests to function.\n" unless $loaded;}

BEGIN {
print "WARNING: You cannot run these tests unless JavaServer is running!\n";
print "Do you want to continue? (Y/n) ";
my $in = <STDIN>;
exit 1 if ($in =~ /^n/i);
}
use lib '.';
use Java;
my $java = new Java();
$loaded = 1;
$ok++;
print "ok $ok\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
# If you 'use strict' you gotta use 'no strict 'subs'' 'cuz all the
# function calls are AUTOLOADED...
	
#no strict 'subs';

print "Create array.\n";
my $array = $java->create_array("java.lang.String",5);
$ok++;
print "ok $ok\n";

print "Set array field.\n";
$array->[3] = "Mark Rulez";
$ok++;
print "ok $ok\n";
print "Get length.\n";
my $len = $@{$array};
$ok++;
print "ok $ok\n";

print "Get value.\n";
my $vv =  $array->[3]->get_value;
$ok++;
print "ok $ok\n";
#print "ARRAY: $vv $len\n";
# $array->set_value(0,$constructor);
# $my vv = $array->get_value(3);

print "Dynamic Class Loading.\n";
my $class = $java->java_lang_Class("forName","com.zzo.javaserver.Test");
#my $class = $java->static_call("java.lang.Class","forName","Test");
$ok++;
print "ok $ok\n";

print "Get array from reflection.\n";
my $constructor_array = $class->getConstructors();
$ok++;
print "ok $ok\n";

print "Cycle thru array values.\n";
for (my $i = 0; $i < $#{$constructor_array}; $i++)
{
	my $cons = $constructor_array->[$i];
	my $val = $cons->get_value();
	print "Constructor $i: $val\n";
}
$ok++;
print "ok $ok\n";

#
# array syntax for JavaServer
# don't worry about this!  just showin' ya what these Perl
# calls get mapped to...
# NEW [Ljava.lang.reflect.Constructor;(5 (,34,2,3,2))
# GET [Ljava.lang.reflect.Constructor;^3#2
# SET [Ljava.lang.reflect.Constructor;^3#(<object>)
# GET [Ljava.lang.reflect.Constructor;^3#len	== get length

print "New instance of dynamically loaded class.\n";
my $test_obj = $class->newInstance();
$ok++;
print "ok $ok\n";

print "Method call on dynamically instantiated class.\n";
my $val = $test_obj->get->get_value;
$ok++;
print "ok $ok\n";

print "Static get field all in one line.\n";
my $str = $java->get_field("java.util.Locale","CHINESE")->getDisplayName->get_value;
print "Chinese Locale: $str\n";
$ok++;
print "ok $ok\n";

my $windows = 2;

print "GUI and Events.\n";
print "Create frame.\n";
$ok++;
print "ok $ok\n";
my $frame = $java->create_object("java.awt.Frame","Frame #1");

print "Set size.\n";
$frame->setSize(200,200);
$ok++;
print "ok $ok\n";

print "Show.\n";
$frame->show();
$ok++;
print "ok $ok\n";

print "Frame1 is $frame->{name}\n";
print "Set up Window Events.\n";
$java->do_event($frame,"addWindowListener",\&event);
$ok++;
print "ok $ok\n";

print "Add a dialog box\n";
my $dialog = $java->create_object("java.awt.Dialog",$frame,"Dialog Box","true:b");
$ok++;
print "ok $ok\n";

print "Set dialog box size.\n";
$dialog->setSize(400,400);
$ok++;
print "ok $ok\n";

print "Show dialog.\n";
#$dialog->show();
$ok++;
print "ok $ok\n";

print "Set up Window Events for dialog.\n";
$java->do_event($dialog,"addWindowListener",\&event);
$ok++;
print "ok $ok\n";

print "Second frame.\n";
my $frame2 = $java->create_object("java.awt.Frame","Frame #2");
$ok++;
print "ok $ok\n";

print "Set size.\n";
$frame2->setSize(200,200);
$ok++;
print "ok $ok\n";

print "Show second frame.\n";
$frame2->show();
$ok++;
print "ok $ok\n";

print "Set up events on second frame.\n";
$java->do_event($frame2,"addWindowListener",\&event);
$ok++;
print "ok $ok\n";

print "Enter event loop.\n";
while(1)
{
	my $b = $java->go;
	last if (!defined $b);
	last if ($windows <= 0);
}
$ok++;
print "ok $ok\n";

sub event
{
	my($object,$event) = @_;
	# Used to discern what window event happened
	my $val = $event->getID->get_value;

print "Got event $event on $object\n";
	if ($object->same($frame))
	{
		print "Event on Frame 1: ";
	}
	elsif ($object->same($dialog))
	{
		print "Event on Dialog box: ";
	}
	else
	{
		print "Event on Frame 2: ";
	}
	
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
		# if ya close the first frame it'll take the dialog box
		#	down with it...
		$object->dispose;
		$windows-- if (!$object->same($dialog));
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

#okay this is a weird one
print "Server socket test - this is a weird one!\n";
print "You type in below what port you want a echo server to start listening\n";
print "on & I'm gonna tell the JavaServer to start listening on port in.\n";
print "You telnet to the port on localhost in another window & it'll\n";
print "echo each line you type.\n";
print "Type 'bye' when finished...\n";
#print "First off - do you want to run this test?  If you've got this far\n";
#print "most likely you're okay.... (y/N)? ";
#my $in = <STDIN>;
#exit 1 if ($in !~ /^y/i);
print "What port should the echo server listen on (8000 is the default)? ";
my $port = <STDIN>;
chomp $port;
$port = 8000 if ($port =~ /\D/ || !$port);

print "Creating server socket on port $port.\n";
my $ssocket = $java->create_object("java.net.ServerSocket",$port);
$ok++;
print "ok $ok\n";

print "Accepting connexions.\n";
my $client = $ssocket->accept;
$ok++;
print "ok $ok\n";

print "Got a connexion!\n";
print "Getting InputStream.\n";
my $is = $client->getInputStream;
$ok++;
print "ok $ok\n";

print "Getting OutputStream.\n";
my $os = $client->getOutputStream;
$ok++;
print "ok $ok\n";

print "Creating InputStreamReader.\n";
my $isr = $java->create_object("java.io.InputStreamReader",$is);
$ok++;
print "ok $ok\n";

print "Creating OutputStreamWriter.\n";
my $osw = $java->create_object("java.io.OutputStreamWriter",$os);
$ok++;
print "ok $ok\n";

print "Creating BufferedReader.\n";
my $buffered_reader = $java->create_object("java.io.BufferedReader",$isr);
$ok++;
print "ok $ok\n";

print "Creating PrintWriter.\n";
my $print_writer = $java->create_object("java.io.PrintWriter",$osw,"true:b");
$ok++;
print "ok $ok\n";

my $cont = 1;

print "Entering input loop.\n";
while($cont)
{
	print "Waiting to get a line.\n";
	my $input_line = $buffered_reader->readLine;
	last if (!$input_line);
	$input_line = $input_line->get_value;
	chomp $input_line;
	print "Received: $input_line\n";

	print "Sending echo to client.\n";
	$print_writer->println("You typed - $input_line");
	if ($print_writer->checkError->get_value eq 'true')
	{
		print "ERR: true!\n";
	}
	$cont = 0 if ($input_line =~ /^bye/i);
}
$ok++;
print "ok $ok\n";

###
# Swing tests!
###
print "Now go into the examples/swing directory if you want to run Swing tests...\n";
