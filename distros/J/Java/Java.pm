# $Header: /cvsroot/javaserver/javaserver/JavaServer/perl/Java.pm,v 1.3 2004/02/25 07:52:15 zzo Exp $
# $Revision: 1.3 $
# $Log: Java.pm,v $
# Revision 1.3  2004/02/25 07:52:15  zzo
# - Fix test scripts to use local Java.pm & Test & Test2 classes in the
# com.zzo.javaserver package
# - added 'destroy' method to Java.pm so y'all can hand destroy objects
#
# Revision 1.2  2004/01/19 23:28:59  zzo
# Moved the java files around to put them in 'com.zzo.javaserver' package
# Fixed test script
#
# Revision 1.1.1.1  2003/11/17 22:08:07  zzo
# Initial import.
#
# Revision 1.16  2003/06/24 17:28:48  mark
# - Correctly encode parameter value for static set_field calls
# - 'die' instead of exit on authentication failure
# - anchor 'false:b' regex in pretty_args
# - try to make install more platform independent
#
# Revision 1.15  2003/04/14 22:50:51  mark
# allow negative integers, test fix
#
# Revision 1.14  2002/09/03 17:26:43  mark
# bump version #
#
# Revision 1.13  2002/09/03 17:21:03  mark
# Fix Makefile.PL so EXE_FILES are an anon array
# When checking for ERROR make sure it must begin on beginning of line!
# Better perldocs
#
# Revision 1.12  2001/11/30 19:18:52  mark
# Windows fix
#
# Revision 1.11  2001/08/13 18:36:08  mark
# Make the auth secret stuff work w/Winblows & Krapple by getting rid of
# '\015' chars @ end of line
#
# Revision 1.10  2001/08/02 16:05:14  mark
# Fix for Windows authentication
#
# Revision 1.9  2001/08/01 21:53:08  mark
# version to 4.1.1
#
# Revision 1.8  2001/08/01 21:51:38  mark
# Fixed generic handling of pulling out instance data from 'java' object
#
# Revision 1.7  2001/07/29 21:18:37  mark
# VERSION up to 4.1
#
# Revision 1.6  2001/07/20 22:39:44  mark
# Allow blank lines for callbacks
#
# Revision 1.5  2001/07/17 15:50:25  mark
# Made sure exceptions are stored in the 'java' object & not the
# instantiated object.  added some convenience functions for this too
#
# Revision 1.4  2001/07/13 14:59:51  mark
# Put eval'ed callbacks in package main by default like it should have been
# in the first place
#
# Revision 1.3  2001/07/10 18:47:36  mark
# Changed '\r' to more portable '\015'
#
# Revision 1.2  2001/07/09 23:05:51  mark
# Clean up
#
# Revision 1.1.1.1  2001/07/09 22:33:57  mark
# Initial Toss In
#
# Revision 1.2  2000/05/15 21:24:37  markt
# This is da Big Daddy
#

package Java;

# Perl5 is good enough for me I think
require 5;

##
# If you 'use strict' you have to do 'no strict 'subs'' 'cuz all Java
#	function calls are AUTOLOAD'ed - sorry.
##

use Socket;
use Symbol;
use Carp;

# NOTE - you may have to 'use IO::Socket::INET' if yer perl install
#	is cracked...
use IO::Socket;

# Fancy pants array stuff
use JavaArray;

# Now allow '==' to mimic 'same' functionality
use overload '==' => "same", 'fallback' => 1;

use vars qw ($AUTOLOAD @ISA $VERSION);

require Exporter;
@ISA = qw(Exporter);

$VERSION = '4.7';

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Java ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

# Extremely cheesy
use constant PARAMETER_SEPARATOR => "";

use constant NULL_TOKEN => "___NULL___";

# Preloaded methods go here.
sub new
{
	my $self = {};
	bless $self, shift;
	$self->_init(@_);
	return $self;
}

##
# When ya first create one of these monsters it'll try to connect
#	to JavaServer running on
#	host => host
#	port => port
#
#	And the JavaServer will attempt to connect to US on event_port...
#	event_port => event port
#
#	supplied in 'new' arguments or use defaults
#	'localhost', 2000 & 2001
#
#       Also it'll use old-style arrays  if specified.
sub _init
{
	my($self,%attrs) = @_;

	$self->{port} = $attrs{port} || 2000;
	$self->{host} = $attrs{host} || "localhost";
	$self->{event_port} = $attrs{event_port} || 2001;

	# It's now the default!
	$self->{use_tied_arrays} = 1 unless $attrs{use_old_style_arrays};

	##
	# Set up them sockets!
	##

	# Client/control socket
	$self->{socket} = IO::Socket::INET->new
		(
			PeerAddr => $self->{host},
			PeerPort => $self->{port}
		);

	if (!$self->{socket})
	{
		croak("Client socket error: $!");
	}
	# Make sure we're autoflushed
	$self->{socket}->autoflush(1);

	my $authSecret = "";

	# Check for authorization file & use it!
	if (defined($attrs{authfile}))
	{
		open(AUTH,$attrs{authfile}) or croak("Could not open ".$attrs{authfile}.": $!\n");
		$authSecret=<AUTH>;
		close(AUTH);
		$authSecret =~ s/\015//g;	# clean up input from Winblows
		chomp($authSecret);
	}

	# Send Auth token
	$self->{socket}->print("AUTH: ".$authSecret."\n");

	# Check response
	my $line = $self->{socket}->getline;
	$line =~ s/\015//g;	# clean up input from Winblows
	chomp $line;

    die("Authentication Failed: $line") unless ($line =~ 'OK');

	# Set to '-1' to disable events
	if ($self->{event_port} > 0)
	{
		#
		# Set up our event_socket server
		#
		$self->{event_server} = IO::Socket::INET->new
			(
				Listen => 5,
				LocalPort => $self->{event_port},
				Proto => 'tcp',
				Reuse => 1
			);
	
		if (!$self->{event_server})
		{
			croak("Couldn't create event_server socket: $!");
		}
	}

	## Tell JavaServer what port we want our events on...
	$self->{socket}->print($self->{event_port}."\n");

	if ($self->{event_port} > 0)
	{
		# Don't wanna do nuthin' until we hear from JavaServer on our
		#	event_server port
		my $peer_address;
		($self->{event_socket}, $peer_address) = $self->{event_server}->accept;
	
		#my($port, $iaddr) = sockaddr_in($peer_address);
		#$iaddr = inet_ntoa($iaddr);
		#print STDERR "Event port connexion from $iaddr:$port!\n";
	
		# Don't wanna accept any more event_server connexions
		undef $self->{event_server};

		# AutoFlush this bad boy
		#	We're only gonna use this monster to read events
		$self->{event_socket}->autoflush(1);
	}
}

###
# This is used to create a new Java object
###
sub create_object
{
	my($self,$what,@args) = @_;

	# pretty up the arguments for java-land
	@args = pretty_args(@args);

	local($") = PARAMETER_SEPARATOR;
	my $resp = $self->send_command_and_get_response("NEW $what(@args)");
	#
	# Create a new java object
	#
	$self->new_java_object($resp);
}

# Get callback object so server side can make perl calls
sub get_callback_object
{
	my($self) = @_;

	my $resp = $self->send_command_and_get_response("BCK");

	$self->new_java_object($resp);
}

# Guess what this does...
sub create_array
{
	my($self,$what,@indicies) = @_;
	
	# We don't need to pretty args here....  all assumed to be ints
	#	and need to be separated by commans NOT PARAMETER_SEPARATOR
	local($") = ",";
	my $resp = $self->send_command_and_get_response("NEW [L$what;(@indicies)");
	$self->new_java_object($resp);
}

# Hmmm... wonder what this does?
sub set_field
{
	my($self,$index,@args) = @_;
	
	# pretty up the arguments for java-land
	@args = pretty_args(@args);

	local($") = PARAMETER_SEPARATOR;
	my $line;

	# Figure out what we're dealing with...
	if ($self->_is_java)
	{
		# static object
		$line = "SET $_[1]#$_[2](@args[1..$#args])";
        print "STATIC LINE: $line\n";
	}
	else
	{
		# instantiated object
		$line = "SET $self->{name}#$index(@args)";
	}
	
	my $resp = $self->send_command_and_get_response($line);
	$self->new_java_object($resp);
}

sub get_length
{
	# Get an array's length
	my($self) = @_;
	my $line = "GET $self->{name}#LEN";
	my $resp = $self->send_command_and_get_response($line);
	# We're just getting a raw integer back here...
	chomp $resp;
	$resp;
}



###
# Bless the returned string into a 'Java' object
#	& be mindful of if this 'self' already points to a
#	java object or not
###
sub new_java_object
{
	my($self, $line) = @_;
	chomp $line;

	# NULL!
	return 0 if ($line eq 'NUL');

	#
	# If we're creating this object from another one
	#	i.e. from a method call
	# pull the 'java' portion outta there...
	my $java = $self->_get_in_java('java');

	#print STDERR "Created Java Object $line\n";
	my $obj = (bless { name => $line, java => $java }, ref $self);

        #
        # If we're using the tied array syntax convert this guy into
        #       a tied array IF INDEED it is an array that is!
        #
        if ($java->{use_tied_arrays})
        {
                if ($line =~ /^\[/)
                {
                        my @java_object;
                        tie @java_object, 'JavaArray', $obj;
                        return \@java_object;
                }
        }

        # Otherwise just return the thang
        return $obj;
}

# Gets the client socket
sub get_socket
{
	my ($self) = shift;
	$self->_get_in_java('socket');
}

# Gets the incoming event socket
sub get_event_socket
{
	my ($self) = shift;
	$self->_get_in_java('event_socket');
}

sub send_line
{
	my($self,$line) = @_;
	return if (!$self || !defined($line));
	print "Sending line: $line\n" if $DEBUG;
	$self->get_socket->print("$line\n\n");
}
	
sub send_command_and_get_response
{
	my($self,$line) = @_;
	my $resp = "";
	if ($self->send_line($line))
	{
		# The response ends w/a  on a line by itself
		while (1)
		{
			my $line;
			$line = $self->get_socket->getline;
			if (!defined $line)
			{
				croak("Error receiving response");
			}
			$line =~ s/\015//g;	# clean up input from Winblows

			# Check for end of response
			last if ($line =~ /^$/);

			$resp .= $line;
		}

		chomp $resp;	# clean up last newline

		# Pull out the Exception object if it's there
		if ($resp =~ /^ERROR/)
		{
			# Peel off Exception object if it's there
			if ($resp =~ s/%%%(.*)$//)
			{
				# & keep track of it in the Java object
				my $ex_obj = $self->new_java_object($1);
				$self->_set_in_java('last_exception',$ex_obj);
			}
			croak($resp);
		}

		return $resp;
	}
	else
	{
		croak("Error sending $line");
	}
}

# Gets the most recent Exception object
sub get_exception
{
	my($self) = @_;
	$self->_get_in_java('last_exception');
}

#
# Does the nasty work for ya to get the Stack Trace for
#	the most recent Exception
# Returns array of stack trace lines
#
sub get_stack_trace
{
	my ($self) = @_;

        my $exception_object = $self->get_exception;

	# Get the Stack Trace - blame Java for this mess!
        my $string_writer = $self->create_object("java.io.StringWriter");
        my $print_writer = $self->create_object("java.io.PrintWriter", $string_writer);
        $exception_object->printStackTrace($print_writer);

	my $line = $string_writer->toString->get_value;
	$line =~ s/\015//g;	# Get rid of Windows/Krapple nastiness
	split(/\n/, $line);
}

## This'll return an objectified field from a static or instantiated reference
# you ken this call 'get_value' on this monster to string-ify it...
#	Also gets array elements...
sub get_field
{
	my($self) = shift;
	my $resp;
	if ($self->_is_java)
	{
		# Get static field
		$resp = $self->send_command_and_get_response("GET $_[0]#$_[1]");
	}
	else
	{
		# Get instantiated field
		$resp = $self->send_command_and_get_response("GET $self->{name}#$_[0]");
	}

	# Objectify it
	return $self->new_java_object($resp);
}

## This'll return an STRING value from a static or instantiated reference
sub get_value
{
	my($self) = shift;
	if ($self->_is_java)
	{
		# Get static value
		$self->send_command_and_get_response("VAL $_[0]");
	}
	else
	{
		# Get instantiated field value
		$self->send_command_and_get_response("VAL $self->{name}");
	}
}

# Convert 'perl' type args to 'java' type args
sub pretty_args
{
	##
	# Append type name to each primitive arg
	#	Gotta add all them other primitive types here...
	##
	foreach (@_)
	{
		if (!defined)
		{
			# Wanna pass 'null' in
			$_ = NULL_TOKEN;
		}
		elsif (/^-?\d+$/)
		{
			# If it looks like an INT it is an int...
			$_ .= ":int";
		}
		elsif (/^true:b$/i || /^false:b$/i)
		{
			# Stick that 'oolean' @ the end of ':b'!
			$_ .= "oolean";
		}
		elsif (/:char$/i || /:short$/ || /:float$/ || /:double$/
			|| /:byte$/ || /:long$/)
		{
			#leave it alone
		}
		elsif (ref $_)
		{
                        # It's a JavaArray - we get the actual underlying
                        #       'Java' object by pop'ing the array...
                        #       who knew?
                        if (ref $_ eq 'ARRAY')
                        {
                                $_ = pop @$_;
                        }

			# It's a Java object already
			$_ = $_->{name};
		}
		else
		{
			# It's a string
			# in case it's an integer w/a ':string' already at the
			#	end of it
			# Or it is an encoding string like "Unicdoe:string_UTF"

			# Either way we gotta put quotes around it & append
			#	it w/:string or w/:string_<ENCODING>

			# Put quotes around it
			$_ = "\"".$_;
			unless (s/:string/\":string/)
			{
				# Regular string
				$_ .= "\":string";
			}
		
		}
	}
	@_;
}

sub get_chars_from_dec
{
	# Makes 2-byte hex ints...
	unpack("H*",pack("n",shift));
}

sub create_raw_string
{
	# This is dicey!!!

	my($self,$encoding,$string) = @_;

	my @all_bytes;
	my @chars = split //, $string;
	foreach (@chars)
	{
		# Makes integers outta chars...
		push @all_bytes, unpack("C",$_);
	}

	## @all_bytes is now an array of integer bytes values representing
	#	the unicode string
	##

	my $len = @all_bytes;
	my $line = "BYTE java.lang.String $encoding $len";
	$self->send_line($line);

	# Wait for response
	my $resp = $self->get_socket->getline;

	# Send bytes
	local($") = " ";
	$resp = $self->send_command_and_get_response("@all_bytes");
	$self->new_java_object($resp);
}

sub do_event
{
	my($self,$object,$func,$callback) = @_;

	my $object_name = $object->{name};
	my $resp = $self->send_command_and_get_response("EVT $object_name(\"$func\")");
	$func =~ s/listener//i;

	##
	# So this'll look like
	#	$self->events->java.awt.Frame^234->Window = $callback
	#	so all 'Window' events for java.awt.Frame^234 will point
	#	to a 2-keyed hash containing the object itself & the callback
	#	to callback...
	#
	if ($func =~ s/^add//)
	{
		$self->{events}->{$object_name}->{$func} = 
						{ 
							obj => $object,
							callback => $callback
						};
	}
	else
	{
		$func =~ s/remove//;
		delete $self->{events}->{$object_name}->{$func};
	}
}

##
# One of our java objects has gone out of scope so tell JavaServer about it
#	OR the main java object is gone & we're done...
sub DESTROY
{
	my($self) = shift;
	if ($self->_is_java)
	{
		# Entire Java hash going out of scope
		$self->{socket}->close() if ($self->{socket});
	        $self->{event_socket}->close() if ($self->{event_socket});
    undef $self;
	}
	else
	{
		# Plain old scalar - java object
		# Tell JavaServer we're done w/it...
		my $resp = 
      $self->{java}->send_command_and_get_response("BYE $self->{name}");
    undef $self;
	}
}

sub destroy 
{
	my($self) = shift;
	if (!$self->_is_java)
	{
		my $resp = 
      $self->{java}->send_command_and_get_response("BYE $self->{name}");
    undef $self;
  }
}

##
# This'll capture all function calls...
##
sub AUTOLOAD
{
	my($self,@args) = @_;
	my ($func) = $Java::AUTOLOAD =~ /::(.+)$/;
	my @goo;

	# it's a static call UNLESS $self is an instantiated class
	if ($func =~ /_/ && $self->_is_java)
	{
		# called like $java->java_lang_Class("forName","java.lang.String");
		# Pull out object name
		my $obj;
		($obj = $func) =~ s/_/\./g;
		push @goo, $obj;
	}
	else
	{
		# regular method call
		# called like $frame->setSize(200,200);
		# Pull out object name & function name
		push @goo, $self->{name}, $func;
	}

	return base_call($self,@goo,@args);
}

#
# Make a static function call if yer object ain't in a package...
#
# Called like 
# $java->static_call("MyStaticClass","function_name","param1","param2"....);
#
sub static_call
{
	return base_call(@_);
}

# wrapper routine for instantiated calls
sub call
{
	my $self = shift;
	return base_call($self,$self->{name},@_);
}

sub base_call
{
	my($self,$obj,$func,@args) = @_;
	local($") = PARAMETER_SEPARATOR;

	# Make args java-friendly
	@args = pretty_args(@args);

	my $resp=$self->send_command_and_get_response("CAL $obj%$func(@args)");

	# Handle a callback request
	while ($resp =~ s/^CALLBACK //)
	{
		# eval it  - put it in package main if they don't
		#	specify one themselves
		my $ret = eval("package main;$resp");
		if ($@)
		{
			chomp $@;

			# Something went wrong - send a response back
			$resp = $self->send_command_and_get_response($@);

			# & tell someone
			print STDERR "Remote callback failed: $@";
		}

		$ret ||= "";
		$resp = $self->send_command_and_get_response($ret);
	}

	return $self->new_java_object($resp);
}

##
# This compares two objects to see if they're the same one!
#	pretty much only useful for event handling I think...
##
sub same
{
	my($self,$other_obj) = @_;
	$self->{name} eq $other_obj->{name};
}

###
# The Event Loop
#	Just sit around & wait for 1 line from the JVM 
#	return undef is there's a problem
#	return whatever the event handler returned if alls kool
##
sub go
{
	my $self = shift;

	# Mite not be using events
	return if (!$self->get_event_socket);

	my $READBITS = 0;
	vec($READBITS,$self->get_event_socket->fileno,1) = 1;
	my $nf = select(my $rb = $READBITS,undef,undef,0);

	return if (!$nf);

	my $line = $self->get_event_socket->getline;
	return if (!defined $line); 	# lost somebody

	$self->decipher_event($line);
}

##
# Decipher & Dispatch this event
##
sub decipher_event
{
	my($self,$line) = @_;

	chomp $line;
	$line =~ s/\015//g;	# Clean up input from Winblows...
	
	# figure out who wanted this event
	$line =~ s/^EVE:\s+//;

	# Get the two strings
	my($event_object,$object_name) = split / /,$line;
	
	# Get rid of 'Event'
	my($event) = $event_object =~ /\.(\w+)Event/;

	# Get the hash for this event object
	my $hash = $self->{events}->{$object_name}->{$event};

	# Make the Event object a 'blessed' java object
	my $new_event_obj = $self->new_java_object($event_object);

	# Call the event callback
	$hash->{callback}->($hash->{obj},$new_event_obj);
}

##
# In case someone wants to do the event loop themselves...
##
sub get_event_FH
{
	my $self = shift;
	$self->get_event_socket;
}
	
sub _get_in_java
{
	my($self,$what) = @_;
	if ($self->_is_java)
	{
		return $self if ($what eq 'java' && !$self->{java});
		return $self->{$what};
	}
	else
	{
		return $self->{java} if ($what eq 'java');
		return $self->{java}->{$what};
	}
}

sub _set_in_java
{
	my($self,$what,$value) = @_;
	if ($self->_is_java)
	{
		return $self->{$what} = $value
	}
	else
	{
		$self->{java}->{$what} = $value;
	}
}

sub _is_java
{
	shift->{socket};
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Java - Perl extension for accessing a JVM remotely or locally

=head1 SYNOPSIS

  use Java;
  $java = new Java;
  $frame = $java->create_object("java.awt.Frame","Frame's Title");
  $frame->setSize(400,400);
  $frame->show();
  $java->do_event($frame,"addWindowListener",\&event_handler);
  
  $array = $java->create_array("java.lang.String",5);
  // Set array element 3 to "Java is lame"
  $array->[3] = "Java is lame";
  $element_value = $array->[3]->get_value();

  $button = $java->create_object("java.awt.Button","Push Me");
  // Listen for 'Action' events from $button object
  $java->do_event($button,"addActionListener",\&event_handler);

  // Loop & wait mode
  while(1)
  {
       my $continue = $java->go;
       last if (!defined $continue);
  }

  // Got an event!
  sub event_handler
  {
	my($object_that_caused_event,$event_object) = @_;
        if ($object_that_caused_event->same($button))
	{
		// From $button!
		print "You pushed my button!!\n";
	}
  }

=head1 DESCRIPTION

This module allows you to talk to a JVM on a local or remote machine.  You
can create objects, call functions, access fields, deal with arrays, get
events & all the nonsense you can do in Java - from Perl!

=head1 Starting a JVM server

First you must run 'JavaServer' on the machine to which you will make
connections.  Simply do a 'java JavaServer' to start the server.  By default
it will start listening on port 2000.  Make sure the 'JavaServer.jar' is in your classpath - also make sure the Swing stuff (JFC if you prefer) is in your classpath as well if you want to use Swing stuff (note this does not apply to JVM 1.2+).

=head1 Creating the root Java object

You connect to a remote (or local) JVM when you create a new Java instance.
The new call accepts a hash with the following keys:

	host => hostname of remote machine to connect to
			default is 'localhost'
	port => port the JVM is listening on (JavaServer)
			default is 2000
	event_port => port that the remote JVM will send events to
			default is 2001.  If you specify '-1' for this
			value then the event service will be turned off -
			if you're not doing any GUI work this might be
			a good idea as the second event port will NOT
			get used/opened saving some system resources.
	authfile => The path to a file whose first line is used as a 
			shared 'secret' which will be passed to 
			JavaServer.  To use this feature you must start 
			JavaServer with the '--authfile=<filename>' 
			command-line option.
			If the secret words match access will be granted
			to this client.  By default there is no shared
			secret.  See the 'Authorization' section below.
	use_old_style_arrays => tell Java.pm to use 'old-style' arrays
			which you should NOT be using unless you need
			backwards compatibility with 3.x Java.pm & 
			earlier.  By default all arrays returned by 
			JavaServer are 'tied' to the JavaArray class for 
			easier perl-like manipulation.  See the 'Arrays' 
			section futher down for more info.

For example:

	$java = new Java(host => "java.zzo.com", event_port => 4032);

	# No events!
	$java2 = new Java(port => 8032, event_port => -1);

You can have any number of java 'environments' in a Perl program.

Also if you 'use strict' you must do a 'no struct 'subs'' 'cuz all Java method calls are AUTOLOAD'ed - sorry.

=head1 Creating java primitives

The Java.pm module will treat all integers encountered in parameter
lists as integer and strings as java Strings.  All other primitive types
must be suffixed with an identifier so Java.pm knows what primitive Java
type to convert it to - for instance boolean types are tagged like:
	"true:b" or "false:b"

Here's a complete list of supported Java primitives:

	Perl String Value  -> (converted to) -> Java Primitive
	-----------------			--------------
	2344					int
	"23:short"				short
	"23:byte"				byte
	"a:char"				char
	"23445:long"				long
	"3.42:float"				float
	"3.14159:double"			double
	"true:b" or "false:b"			boolean
	"Anything else"				String
		or
	"Anything else:string"			String

So... if you need to use an integer as a String say "343:string".

=head1 Localization and String encoding

Quick note on String encodings, you can specify that your strings are encoded
in a specific format using the ":string_<ENCODING>" syntax like:

	my $label = $java->create_object("java.awt.Label","Label:string_UTF8");

This specifies that this String uses Unicode encoding.  See 
http://www.javasoft.com/products/jdk/1.1/docs/guide/intl/encoding.doc.html
for the complete list of valid Java String encodings.

=head1 Creating java objects

Once you've connected to a JVM via the 'new Java' call you can start creating
Java objects.  This is accomplished via the 'create_object' function.
The first argument must be the 'fully-qualified'/'full path' of the Java object
you want to create - like 'java.lang.String' or 'java.awt.Frame'.  
The remaining arguments are passed to that object's constructor.

For example:

	my $frame = $java->create_object("java.awt.Frame","Frame Title");
	my $dialog = $java->create_object("java.awt.Dialog",$frame,
			"Dialog Title","true:b");

Note the use of "true:b" in the constructor to tell Java.pm that that 
value should be a 'true' Java boolean value.

In these cases a 'java.awt.Frame' takes a String as the lone parameter, 
whereas a 'java.awt.Dialog' takes a Frame, a String, and a boolean value 
in its constructor.

=head1 Calling java methods

You can make both static and instantiated method calls on java objects.
The parameter lists work exactly like constructor parameter lists - if you
want to pass a java primitive anything other than integers or Strings need
to be tagged accordingly.  All function calls that return something return
a java object - so even if the java function returns an 'int' it is returned
to perl as a 'java.lang.Integer'.  To get the value of that Integer you must
use the 'get_value' function.
The syntax is exactly what you'd expect (I hope!).

For example:

	$frame->setSize(200, 500);
	$frame->show();  # (or $frame->show)

Note functions that don't take any parameters don't need the parentheses!
Alternatively you can use the 'call' function to make method calls:

	$frame->call('setSize', 500, 500);
	$frame->call('show');

But that's no fun!
	
To call static functions the syntax is slightly different.

For example:

To call the static method 'forName' in the object 'java.lang.Class'
it looks like this:

	my $class = $java->java_lang_Class("forName", "Test");

Note you use the '$java' object returned from the call to 'new Java'
to access static methods - the static object must be fully-qualified
separated by '_'s instead of '.'s WHEN USED AS A FUNCTION NAME (as
opposed to the method below when it's used as a string - in the below
case DO NOT replace '.'s with '_'s)!  And finally the first parameter 
is the name of the static function followed by any parameters to it.

If your static class is NOT in a package you MUST use the 'static_call'
function like:

	my $return_value = $java->static_call("MyStaticClass","<function_name>",@params);

Even if your class is in a package you can use the 'static_call' function
(Note when using the 'static_call' function your fully qualified class name
is separated by '.' NOT '_'s as in the example above):

    my $class = $java->static_call("java.lang.Class", "forName", "Test");
        IS EXACTLY EQUIVALENT TO
	my $class = $java->java_lang_Class("forName", "Test");

Note the use of '.'s in the first case and '_'s in the second case.
Also the returned value '$class' in an OBJECT NOT a string.  To
'stringify' it use the 'get_value' function as described below.
Here's a sneak peek:

    print "This java.lang.Class object's name is ", $class->get_value, "\n";

=head1 Getting and Setting java object fields

You can get and set individual fields in java objects (static or instantiated) 
using the 'get_field' and 'set_field' methods.  All 'get_field' calls return
java objects just like calling java functions.  You must use the 'get_value'
function to 'unwrap' primitive types to their actual values.

For example:

Get a static field 

	my $win_act = $java->get_field("java.awt.event.WindowEvent",
						"WINDOW_ACTIVATED");

Note the first parameter must be the fully qualified java object name 
and the second parameter is the static field.

Get an instantiated field

	my $obj = $java->create_object("java.my.Object");
	my $field = $obj->get_field("my_field");

Similarly to set a field another parameter is added to the 'set_field' call
with the object that the specified field is to be set to:
	
Set a static field

	$java->set_field("java.static.Object","field_name",$obj);

Set an instantiated field

	$obj->set_field("integer_field_name",400);

=head1 Getting values

To 'unwrap' java primitives (including Strings) you need to call the
'get_value' function.  This will stringify any object given to it -
typcially this is only useful for 'unwrapping' java primitives and
Strings.  Note for all other object the 'toString()' method is called.

For example:

	my $string1 = $java->create_object("java.lang.String","Mark");
	my $string2 = $java->create_object("java.lang.String","Jim");

	if ($string1 eq $string2)
	{
		# WRONG!!!  
		# $string1 & $string2 are objects!
	}

	if ($string1->get_value eq $string2->get_value)
	{
		# RIGHT!!!
		# now you're comparing actual strings...
	}

=head1 Arrays - new style!

Arrays are created with the 'create_array' function call.  It needs a
fully-qualified java object or primitive name and a dimension.

        If you specified 'use_tied_arrays' in your constructor to Java.pm
        (& I think you should unless you have to perserve backwards 
        compatibility...) all Java array references will be 'tied' to the
        JavaArray class allowing a more intuitive interface to your array.

        All array references will be _references_ to these objects.  
        Here's how it looks (compare with 'old style' below):

	# This will create a String array with 100 elements
    #       (this is the same)
	my $array  = $java->create_array("java.lang.String",100);

    # Now it gets interesting!
	# Don't forget on primitive arrays to use the ':' notation!
	$array->[22] = "Mark rules the free world";

	# Get element #99
	my $element_99 = $array->[99];

To get the length or size of an array do what you'd expect (I hope!)

For example:

	my $length = scalar (@$array);
	my $size = $#{@array};

        (remember you get an arrayref there sonny...)

To pass as a function parameter just pass it in as normal:

        my $list = $java->java_util_Arrays("asList",$array);

=head1 Arrays - old style

Arrays are created with the 'create_array' function call.  It needs a
fully-qualified java object or primitive name and a dimension.

For example:

	# This will create a char array with 100 elements
	my $char_array  = $java->create_array("char",100);

	# This will create a String array with 5 elements
	my $string_array = $java->create_array("java.lang.String",5);
		
Array elements are get and set using the 'get_field' and 'set_field' function calls.

For example:

	# Set element #22 to 'B'
	# Don't forget on primitive arrays to use the ':' notation!
	$char_array->set_field(22,"B:char");

	# Set element #3 to 'Mark Rox'
	$string_array->set_field(3,"Mark Rox");

	# Get element #99
	my $element_99 = $char_array->get_field(99);

	# Get element #4
	my $element_4 = $string_array->get_field(4);

	# Don't forget to get the actual string value you gotta call
	#	'get_value'!
	my $char_value = $char_element_99->get_value;
	my $string_value = $string_element_4->get_value;

To get the length of an array use the get_length function.

For example:

	my $length = $string_array->get_length;

Note this will return an actual integer!  You do not need to call 'get_value' on 'get_length's return value!

=head1 Passing & receiving the 'null' value

To pass a 'null' in a function parameter list or to set a field or array 
index, used Perl's 'undef'.  So:

	$object->function($param1, undef, $param2);

Will pass 'null' as the second parameter to that function.  Similarly
to set a field or array index to null:

	$object->set_field("fieldname",undef);	# Set field to null
	$array->[4] = undef;	# Set array value to null

Of course if the field or array type is a primimtive type you will get
a NullPointerException - Java doesn't seem to like that!
	
If a function returns null or a field or array index is equal to null,
you will recieve 'undef' back.  Note this is indistinguishable (sp??)
from a function with a 'void' return value.  So:

	my $retval = $object->function($param1,$param2,undef,"Another param");
	print "It returned NULL\n" if (!$retval);

Similarly:

	my $f_value = $object->get_field("someField");
	print "someField is NULL\n" if (!$f_value);

	my $a_value = $array->[38];
	print "Array index 38 is NULL\n" if (!$a_value);

If someone can think of a good reason why the null return value should
not be undef or should be different than what a void function returns 
I'd like to hear about it!

=head1 Exceptions

Currently Java.pm will 'croak' when an Exception is encountered in JavaServer.
So the way to deal with them is to enclose your Java expression that might
throw an exception in an 'eval' block & then check the $@ variable to see
if an Exception was indeed thrown.  You then need to parse the $@ variable
to see exactly what Exception was thrown.  Currently the format of the $@
string is: 

	ERROR: java.lang.Exception: some.java.Exception: <more info> at $0 line XX

Note the '<more info>' part is the result of the getMessage() function
of that Exception.  Everything after that is the 
stuff put in there by croak;
the filename & line number of your Perl program.

=head2 get_exception

The actual Exception object that was thrown is available via the
'get_exception' function call.

=head2 get_stack_trace

There is also a convenience function 'get_stack_trace' which will return
the Stack Trace as an array of lines from the most recent Exception thrown.
To see how this is done 'Read The Code Luke' in Java.pm - basically
it just gets the most recent Exception & creates an appropriate 
PrintWriter into which it has Java dump the Stack Trace & then it just 
returns the String-ifized version of it - something you can easily 
(albiet messily) do yourself.

=head1

So here's what an Exception handler can look like:

	my $I;
	eval
	{
		$I = $java->java_lang_Integer("parseInt","$some_string:string");
	};
	if ($@)
	{
		# An exception was thrown!!
		$@ =~ s/^ERROR: //;	# Gets rid of 'ERROR: '
		$@ =~ s/at $0.*$//;	# Gets rid of 'croak' generated stuff

		# Print just the Java stuff
		print "$@\n";

		# This is the actual NumberFormatException object
		my $exception_object = $java->get_exception;

		# There's also this new convenience routines to give
		#	the Stack Trace as an array of lines
		# This returns the Stack Trace from the most recent
		#	Exception thrown 
		my @stack_trace = $java->get_stack_trace;

		local($") = "\n";
		print "Stack Trace:\n@st\n";

	}

So in this example if the scalar $some_string did NOT contain a parsable
integer - say 'dd' - the printed error message would be:

	java.lang.Exception: java.lang.NumberFormatException: dd 

	Stack Trace:
	java.lang.Exception: java.lang.NumberFormatException: dd
        	at Dealer.callFunction(Dealer.java:856)
        	at Dealer.parse(Dealer.java:526)
        	at Dealer.run(Dealer.java:425)


You can most likely ignore all of the 'Dealer' stack frames as
that is internal to JavaServer.  Of course dumping Stack Traces
should only be used while you're debugging anyways!

=head1 Comparing Java objects

The '==' operator is now overloaded to provide this functionality!  Woohoo!
So you can now say stuff like:

	if ($object1 == $object2)
	{
		#They're the same!
	}
	else
	{
		#Not!
	}

Here's the old (other) way of doing the exact same thing:

You can see if two references to java objects actually point to the same
object by using the 'same' function like:

	if ($object1->same($object2))
	{
		# They're the same!
	}
	else
	{
		# Nope, not the same
	}

You'll see why this is useful in the next section 'Events'.

=head1 Events

Events are passed from the remote JVM to Perl5 via a separate event port.
To enable events on an object use the 'do_event' function.  Your callback
function will receive the object that caused the event as its first
parameter and the event object itself as the second parameter.  Here's where
ya wanna use the 'same' function (or the new overloaded '==' operator)
to see what object caused this event if you set up multiple objects to call 
the same event function.

For example:

	my $frame = $java->create_object("java.awt.Frame","Title");
	$java->do_event($frame,"addWindowListener",\&event_handler);
	my $button = $java->create_object("java.awt.Button","Push Me");
	$java->do_event($button,"addActionListener",\&event_handler);

To stop listening for events do:

	$java->do_event($frame,"removeWindowListener");

Where:
- $frame is the object for which you'd like to receive events
- "addWindowListener" specifies the types of events you want to listen for
- \&event_handler is your event callback routing that will handle these events

You will keep receiving events you registered for until you make a "remove"
call or your Java object goes away (out of scope, you destroy it, whatever).

Note the second parameter MUST be of the form:

	"<add | remove><Event Type>Listener"

Default <Event Types> are:

	Component
	Container
	Focus
	Key
	Mouse
	MouseMotion
	Window
	Action
	Item
	Adjustment
	Text

Swing <Event Types> are:

	Ancestor
	Caret
	CellEditor
	Change
	Hyperlink
	InternalFrame
	ListData
	ListSelection
	MenuDragMouse
	MenuKey
	Menu
	PopupMenu
	TreeExpansion
	TreeSelection
	TreeWillExpand

And within most of these <Event Types> there are a number of specific events.
Check out the Java event docs if you don't know what I'm talking about...

Here's what an event handler looks like:
	
	sub event_handler
	{
		my($object,$event) = @_;
		if ($object->same($frame))	# Old sytle
			OR
		if ($object == $frame)		# New style!
		{
			# Event caused by our frame object!
	
			# This will get this event's ID value
			my $event_id = $event->getID->get_value;

			# Get value for a WINDOW_CLOSING event
			my $closing_id = $java->get_field("java.awt.event.WindowEvent","WINDOW_CLOSING")->get_value;

			if ($event_id == $closing_id)
			{
				# Close our frame @ user request
				$object->dispose;
			}
		}
		if ($object->same($button))  	# old style
			OR
		if ($object == $button)		# new style!
		{
			print "You Pushed My Button!\n";
		}
	}

Note return values from event handlers are ignored by Java.pm BUT are
returned from the Event Loop as you'll see in a bit.

Note also how I had to call 'get_value' to get the actualy integer values 
of the 'getID' function return value and the field value of WINDOW_CLOSING.

=head1 Event Loops

Once you've set up your event handlers you must start the event loop
to begin getting events - there are two ways to do this.

	1. Have Java.pm handle the event loop 
	2. Roll your own.

Java.pm's event loop will block until an events happens - typically this 
is what you want but sometimes you might want more control, so I've decided
to be nice this _one_ time & let you roll your own too.

Here's how Java.pm's event loop works for ya:

	#
	# Set up a bunch of events...
	#

	while(1)
	{
		my $cont = $java->go;
		last if (!defined $cont);
	}

Note this works similarly to Tk's event loop.  Your program will
now just sit & respond to events via your event handlers.  Also note that
Java.pm's event loop only handles ONE event & then returns - the return
value is whatever your event handler returned OR undef if there was an
error (like you lost yer connexion to the JVM).

Here's how you can create yer own Event Loop:

You ask Java.pm for a FileHandle that represents the incoming event stream.
You can then select on this FileHandle or do whatever else you want - remember
this is a READ ONLY FileHandle so writing to it ain't going to do anything.
Once you get a 'line' from this FileHandle you can (and probably should)
call 'decipher_event' & the event will be dispatched to your event handler
appropriately - the return value being the return value of your event handler.
This can look something like this:

	## Roll my own event loop

	# Get event FileHandle
	my $event_file_handle = $java->get_event_FH;

	# Set up my select loop
	my $READBITS = 0;
	vec($READBITS,$event_file_handle->fileno,1) = 1;

	# Suck in lines forever & dispatch events
	while(1)
	{
		my $nf = select(my $rb = $READBITS,undef,undef,undef);
		if ($nf)
		{
			my $event_line = <$event_file_handle>;
			$java->decipher_event($event_line);
		}
	}

Note this example is EXACTLY what Java.pm's 'go' function does - if you
roll yer own Event Loop you prolly want to do something more interesting 
than this!

The upshot is you'll probably just want to use the 'go' function but if
you've got some other FileHandles going on & you don't want to block on
just this one you can (and should) use the 'roll your own' method.

=head1 Authorization

Using the 'authfile' key when creating the root Java object
specifies a file whose first line is taken to be a password to
be passed to the remote JavaServer to authenticate the connexion.
JavaServer must be started with the '--authfile=<filename>'
command-line option and the first line of that file must match
to be granted access.  
Note this is a _very_ basic form of authorization -
to maximize it you should restrict the file permissions as much
as possible (i.e. 0600).
Thanks to Achim Settelmeier for the initial implementation!

=head1 EXPORT

None by default.

=head1 AUTHOR

Mark Ethan Trostler, mark@zzo.com

=head1 SEE ALSO

perl(1).
http://www.javasoft.com/.
Any sorta Java documentation you can get yer hands on!
http://www.zzo.com/Java/getit.html

=head1 COPYRIGHT

Copyright (c) 2000-2003 Mark Ethan Trostler

All Rights Reserved. This module is free software.  It may be used, redistributed and/or modified under the terms of the Perl Artistic License. 

(see http://www.perl.com/perl/misc/Artistic.html) 

=cut
