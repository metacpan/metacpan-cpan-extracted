#============================= SimpleHttp.pm =================================
# Filename:  	       SimpleHttp.pm
# Description:         Logger delegate for simple http logging.
# Original Author:     Dale M. Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:20:19 $ 
# Version:             $Revision: 1.10 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use Fault::Delegate;
use Fault::DebugPrinter;
use Fault::ErrorHandler;
use Net::HTTP;

package Fault::Delegate::SimpleHttp;
use vars qw{@ISA};
@ISA = qw( Fault::Delegate );

#=============================================================================
#                      Family internal methods
#=============================================================================
# These operations are alert priority: without them we cannot set up the
# system for use. But... if they are not working we cannot tell anyone so
# we have to print local warnings and hope someone is watching.

sub _write ($$) {
    my ($self,$msg) = @_;
    my ($stamp,$priority,$type,$p,$m) = $msg->get;
    my $line                          = "$stamp $priority $type $p $m";

    my ($code,$text,%headers) =  $self->_sendcommand($self->{'logfn'},$line);
    if ($code ne 200) {
	$self->warn ("Failed log write: ($p: $m) to weblog!");
	return 0;
    }
    return 1;
}

#-----------------------------------------------------------------------------

sub _connect ($) {
    my $self       = shift;

    return 1 if (defined $self->{'web'});

    $self->{'web'} = Net::HTTP->new(Host => $self->{'host'});
    if (!defined $self->{'web'}) {
	$self->warn
	    ("Cannot connect to weblogger at http://$self->{'host'}");
	return 0;
    }
    return 1;
}

#-----------------------------------------------------------------------------

sub _disconnect ($) {
    my $self       = shift;
    $self->{'web'} = undef;
    return 1;
}

#=============================================================================
#                      Local internal methods
#=============================================================================
# write_request returns true if it succeeded.

sub _write_get_request ($$) {
    my ($self,$uri) = @_;

    my $flg = $self->{'web'}->write_request
	('GET' => $uri, 'User-Agent' => "Mozilla/5.0");
    if (!$flg) {
	$self->warn ("Failed to write request to weblogger at " . 
			"http://$self->{'host'}/$uri");
	  return 0;
      }
    return 1;
}

#-----------------------------------------------------------------------------
# write_request returns true if it succeeded.

sub _write_post_request ($$$) {
    my ($self,$uri,$data) = @_;
    my %headers;
    my $flg = $self->{'web'}->write_request('POST',$uri,%headers,"$data");
    if (!$flg) {
	$self->warn ("Failed to write request to weblogger at " . 
			"http://$self->{'host'}/$uri");
	return 0;
    }
    return 1;
}

#-----------------------------------------------------------------------------
# read_response_headers return values are:
# code       standard http codes. 200 for success
# mess       standard http codes. 'OK'
# %headers   hash of response headers
# die        if server does not speak proper http or if max_line_length or
#            max_header_length limits are reached.

sub _read_response_headers ($) {
    my $self = shift;

    my ($code, $msg, %headers) = 
	eval {$self->{'web'}->read_response_headers};
    my $err = $@;
    
    if ($err) { 
	$self->warn ("Failed to read response headers from weblogger at " . 
		      "http://$self->{'host'}/$self->{'uribase'}: $err");
	  return undef;
      }
    if ($code != 200) {
	$self->warn ("Error \'$msg\' ($code) response from Weblogger at " .
		      "http://$self->{'host'}/");
	return undef;
    }
    return ($code,$msg,%headers);
}
	  
#-----------------------------------------------------------------------------
# read_entity_body return values are:
# n is undef on read error
#      0     on EOF
#      -1    if no data could be returned this time
#      >0    number of bytes returned
# die        if server does not speak proper http.

sub _read_entity_body ($$$) {
    my ($self,$buf,$bufsiz) = @_;

    my $n = eval {$self->{'web'}->read_entity_body ($buf,$bufsiz)};
    my $err = $@;

    if ($err) { 
	$self->warn ("Failed to read entity body from weblogger at " . 
		     "http://$self->{'host'}/$self->{'uribase'}: $err");
	return undef;
    }
    if (!defined $n) {
	$self->warn ("Failed to read entity body from Weblogger " .
		      "http://$self->{'host'}/");
	return undef;
    }
    return ($n,$buf);
}

#-----------------------------------------------------------------------------
# Download the contents of the fault table and return it as a list of lines.
# Returns an empty list if it cannot connect to the remote site.

sub _download ($) {
    my $self = shift;

    $self->_write_get_request     ($self->{'syncfn'})   or return ();
    $self->_read_response_headers                       or return ();
    
    my ($buf,$n);
    my $file = "";
    while (1) {
	($n,$buf) = $self->_read_entity_body($buf,1024) or return ();
	last unless $n;
	$file .= $buf;
    }
    return split /\n/, $file;
}

#-----------------------------------------------------------------------------
# Send a command and check the response code.

sub _sendcommand ($$$) {
    my ($self,$uri,$data) = @_;
    my ($code,$msg,%headers);
    $self->_write_post_request($uri,$data) or return undef;
    return ($code,$msg,%headers) = $self->_read_response_headers;
}

#=============================================================================
#                          CLASS METHODS                                    
#=============================================================================
# This is the only user exposed method and thus requires arg checking

sub new ($$$$$$$) {
    my ($class,$host,$loguri,$raiseuri,$clearuri,$syncuri) = @_;
    my $self = bless {}, $class;
    
    if (!defined $host or (ref $host) or !POSIX::isprint $host) {
	$self->warn ("Web logging server name invalid or undefined!");
	return undef;
    }

    if (!defined $loguri or (ref $loguri) or !POSIX::isprint $loguri) {
	$self->warn 
	    ("Web logging base log function uri invalid or undefined!");
	return undef;
    }

    if (!defined $raiseuri or (ref $raiseuri) or !POSIX::isprint $raiseuri) {
	$self->warn
	    ("Web logging base fault raise function uri undefined!");
	return undef;
    }

    if (!defined $clearuri or (ref $clearuri) or !POSIX::isprint $clearuri) {
	$self->warn
	    ("Web logging base fault clear function uri undefined!");
	return undef;
    }

    if (!defined $syncuri or (ref $syncuri) or !POSIX::isprint $syncuri) {
	$self->warn
	    ("Web logging base fault sync function uri undefined!");
	return undef;
    }

    @$self{'host','raisefn','clearfn','syncfn','logfn'} = 
	($host,"$raiseuri","$clearuri","$syncuri","$loguri");

    return ($self->test) ? $self : undef;
}

#=============================================================================
#                          INSTANCE METHODS                                 
#=============================================================================
#			Logger Internal Hook Callback Methods
#=============================================================================
# Callback from Logger when it raises a fault on the web logger.

sub trans01 ($$) {
    my ($self,$msg)                   = @_;
    my ($stamp,$priority,$type,$p,$m) = $msg->get;
    my $line                          = "$stamp $priority $type $p $m";
    my $val                           = 0;

    if ($self->_connect) {
	$val = $self->_sendcommand($self->{'raisefn'},$line);
	$val or $self->warn ("Failed fault raise: ($p: $m) to weblog!");
    }
    $self->_disconnect;
    return 0;
}

#-----------------------------------------------------------------------------
# Callback from Logger when it clears a fault on the web logger.

sub trans10 ($$) {
    my ($self,$msg)                   = @_;
    my ($stamp,$priority,$type,$p,$m) = $msg->get;
    my $val                           = 0;

    if ($self->_connect) {
	$val = $self->_sendcommand($self->{'clearfn'},"$p $m");
	$val or $self->warn ("Failed fault clear: ($p: $m) to weblog!");
    }
    $self->_disconnect;
    return 0;
}

#-----------------------------------------------------------------------------
# Callback from Logger when it initializes it's in-memory fault table from
# data held on the web logger.

sub initfaults ($) {
    my ($self)  = @_;
    my @msglist = ();
    my $p       = $self->processname;
    
    Fault::DebugPrinter->dbg (3, "Dump fault table.");

    my @lines   = ();
    if ($self->_connect) {@lines  = $self->_download;}
    $self->_disconnect;
    
    my $cnt     = $#lines + 1;
    Fault::DebugPrinter->dbg (3, "Found $cnt faults.");
    
    foreach my $line (@lines) {
	my ($tdstamp,$priority,$type,$process,$m) = split ' ',$line,5;
	($process eq $p) or next;
	push @msglist, ($m);
    }
    return @msglist;
}

#=============================================================================
#                          POD DOCUMENTATION                                
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 Fault::Delegate::SimpleHttp - Logger delegate for simple http logging.

=head1 SYNOPSIS

 use Fault::Delegate::SimpleHttp;
 $self = Fault::Delegate::SimpleHttp->new ($host,$loguri,
					   $raiseuri,$clearuri,$syncuri);
 $okay = $self->log                       ($msg);
 $zero = $self->trans01                   ($msg);
 $zero = $self->trans10                   ($msg);
 @list = $self->initfaults;

=head1 Inheritance

 UNIVERSAL
   Fault::Delegate
     Fault::Delegate::SimpleHttp

=head1 Description

The Class manages an http remote logging connection. To utilize this class 
you must impliment a set of cgi scripts according the specs given in the
next section.

SimpleHttp can act as a template if I at some point want to impliment a 
Delegate that uses SSL, or that uses xml messages for two way 
communications.

Note: Each method undef's the Net::Http object it creates before exiting. 
This may or may not assist with re-entrancy in a multi-process environment, 
but it was a lesson learned with mysql db handles. The problem was that if a 
handle was created before processes spawned, it could get carried through into
the child processes and if they used the handles the remote daemon could 
become very confused. Whether this would be true of a web daemon connection 
or not is conjecture, but the undef is a way of playing it safe.

=head1 API For Web Logger

A web site must supply a fairly modest set of scripts to support a minimal
interface with which this module may communicate. Each of these scripts
should return a code of 200 and a message of OK in their response header. 
They all use a common set of fields and field definitions:

=over 4
The time stamp will be in the form: yyyymmddhhmmss.

Priority is the set of priorities defined by Unix syslog.

Type is may be any single word uppercase string that your remote application
wishes to use to classify messages. At the very least it should support the
minimal set described in Fault::Logger.

Process is a single word name of the process that generated the log or fault
message.

Message is a string of arbitrary length, limited only by what the web server
is willing to accept or transmit. It may contain contain any printable
character other than newline. Other formatting characters, such as formfeed,
are also best avoided.

=back 4

There are four cgi scripts you will need at your web logger url.

=over 4

=item log cgi script

This script must accept a POST with a single text line in the request body.

The line will consist of five space delimited fields:

	TimeStamp Priority Type Process Message

Any additional spaces are part of the message field.

The script may then do anything it wants with the message, including
ignoring it.

=item faultraise cgi script

Almost exactly like the log cgi script except that it must at the very least 
remember the process and message portions such that a search may be carried 
out on either field.

If it recieves a message that is exactly the same as of one that is already
stored for the process, do nothing.

=item faultclear cgi script

Similar to the log cgi script, but the body contains only the process and 
message, delimited by the first space. 

	Process Message

If the message is an exact match for a message of an active fault for the
same process, it should be deleted. If the message is not from an active
fault for the process, it should be ignored and discarded. 

=item faultsync cgi script

When called with a GET, it should dump a list of all fault messages, 
one to a line in a response body. Each line should be in the format described 
for log cgi script. 

	TimeStamp Priority Type Process Message

If there are no fault messages, it should return an empty list.

=back 4

=head1 Examples

 use Fault::Delegate::SimpleHttp;
 use Fault::Msg;
 use Fault::Logger;

 my $msg       = Fault::Msg                       ("Arf!");
 my $baz       = Fault::Delegate::SimpleHttp->new ($host,$loguri,
						   $raiseuri,$clearuri,
                                                   $syncuri);
 my $waslogged = $baz->log                        ($msg);

                 Fault::Logger->new               ($baz);
 my $waslogged = Fault::Logger->log               ("Bow! Wow!");

 [See Fault::Logger for a detailed example.]

=head1 Class Variables

 None.

=head1 Instance Variables

 host		Name or ip of the web logger server.
 logfn          URI on the host web server to the log cgi script.
 raisefn        URI on the host web server to the fault raise cgi script.
 clearfn        URI on the host web server to the fault clear cgi script.
 syncfn         URI on the host web server to the fault sync cgi script.

=head1 Class Methods

=over 4

=item B<$self = Fault::Delegate::LogFile-E<gt>new ($host,$loguri,$raiseuri,$clearuri,$syncuri)>

Create an object to allow communications with a remote http based logging
application. Returns undef on failure.

=head1 Instance Methods

=over 4

=item B<$okay = $self-E<gt>log ($msg)>

Send a log message to the web logger of the form:

    Time Priority Type Process Message

and return true if we succeeded in doing so. 

=item B<$zero = $self-E<gt>trans01 ($msg)>

Tell the web logger to raise a fault for the current process by sending
a line of the form:

    Time Priority Type Process Message

It always returns 0.

=item B<$zero = $self-E<gt>trans10 ($msg)>

The the web logger to clear a fault for the current process by sending 
a line of the form:

    Process Message

It always returns 0.

=item B<@list = $self-E<gt>initfaults>

Requests a current list of faults from the weblogger when Logger initializes.
@list contains a simple list of strings, where each string represents a 
unique active fault condition belonging to the current process.

 ("fault message 1", "fault message 2", ...)

If it cannot connect to the remote weblogger, an empty list is returned.

=back 4

=head1 Private Class Method

 None.

=head1 Private Instance Methods

=over 4

=item B<$bool = $self-E<gt>_write ($msg)>

=item B<$bool = $self-E<gt>_connect>

=item B<$bool = $self-E<gt>_disconnect>

Impliments the above overrides to the internal family protocol utilized by 
the Fault:Delegate log and test methods.

=back 4

=head1 Errors and Warnings

Local warning messages are issued if the web logger cannot be reached or has 
any problems whatever. You cannot log to a web logger that is not working!

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

 Fault::Logger, Fault::Delegate, Fault::Msg, Net::HTTP,
 Fault::ErrorHandler, Fault::DebugPrinter

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: SimpleHttp.pm,v $
# Revision 1.10  2008-08-28 23:20:19  amon
# perldoc section regularization.
#
# Revision 1.9  2008-08-17 21:56:37  amon
# Make all titles fit CPAN standard.
#
# Revision 1.8  2008-07-24 21:17:24  amon
# Moved all todo notes to elsewhere; made Stderr the default delegate instead of Stdout.
#
# Revision 1.7  2008-05-09 18:24:55  amon
# Bugs and changes due to pre-release testing
#
# Revision 1.6  2008-05-08 20:22:50  amon
# Minor bug fixes; shifted fault table and initfault from Logger to List
#
# Revision 1.5  2008-05-07 18:14:55  amon
# Simplification and standardization. Much more is inherited from Fault::Delegate.
#
# Revision 1.4  2008-05-05 19:25:49  amon
# Catch any small changes before implimenting major changes
#
# Revision 1.3  2008-05-04 14:45:23  amon
# Updates to perl doc; minor code changes.
#
# Revision 1.2  2008-05-03 00:56:57  amon
# Changed standard argument ordering.
#
# Revision 1.1.1.1  2008-05-02 16:37:14  amon
# Fault and Log System. Pared off of DMA base lib.
#
# Revision 1.1  2008-04-25 10:55:20  amon
# Add SimpleHttp module
#
# 20080415 Dale Amon <amon@vnl.com>
#	   Created.
#
# DONE
#	* Put the POST's in a fault check subroutine.	[DMA20080416-20080422]
#	* Change the new method to take a URI for each of the four
#	  methods. Perhaps I can combine the API's and allow it
#	  to EITHER default the fn names OR require 4 full paths
#	  but NOT the base uri.	[DMA20080416-20080422]
#	* Must catch error responses.	[DMA20080417-20080422]
#	* Must catch a 'die' from read_response_headers since that can
#	  happen in some cases.	[DMA20080416-20080422?]
#	* My code might have been misled by the example. I have:
#		$web->write_request('POST',$uri,,$data)
#	  But documentation says the args are:
#		$web->write_request(method,$uri,%headers,[$data])
#	  (Adding %headers does not change anything; bracketing data
#	   causes Kenny to return an error. [DMA 20080422-20080422]
1;

