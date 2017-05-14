#!/usr/local/bin/perl

# Glenn Wood, C<glenwood@alumni.caltech.edu>.
# Copyright 1997-1998 SaveSmart, Inc.
# Released under the Perl Artistic License.
# $Header: C:/CVS/LoadWorm/loadslave.pl,v 1.1.1.1 2001/05/19 02:54:40 Glenn Wood Exp $
#
# see: http://www.york.ac.uk/~twh101/libwww/lwpcook.html

use LoadWorm;
use English;
require 5.004;

#
# provide subclassed Robot to override on_connect, on_failure and
# on_return methods
#
{
package myRobot;
use MIME::Base64 qw(encode_base64);

use Exporter();
use LWP::Parallel::RobotUA qw(:CALLBACK);
@ISA = qw(LWP::Parallel::RobotUA Exporter);
@EXPORT = @LWP::Parallel::RobotUA::EXPORT_OK;

# redefine methods: on_connect gets called whenever we're about to
# make a a connection
sub on_connect {
	my ($self, $request, $response, $entry) = @_;
my $start = LoadWorm->GetTickCount();
#	$start = `systime.exe`; chomp $start;
#	$start = $! unless $start;
	$request->{'_start_systime'} = $start;
	if ( $main::Harvesting ) {
		print main::TIMING "C:$start ",$request->url,"\n";
	}
	if ( $main::Verbose ) {
		print "START ".$request->url."\n";	
	}
##################################################

		my($uid, $pwd) = $self->get_basic_credentials('SaveSmart Release 3', $request->url);
$scheme = 'Basic';
		if (defined $uid and defined $pwd)
		{
			my $uidpwd = "$uid:$pwd";
		   my $header = "$scheme " . encode_base64($uidpwd, '');
			$request->header('Authorization' => $header);
		}
#################################################	
	return undef;
}

# on_failure gets called whenever a connection fails right away
# (either we timed out, or failed to connect to this address before,
# or it's a duplicate)
sub on_failure {
	my ($self, $request, $response, $entry) = @_;
	&LoadWorm::slave_unit(2, $request, $response);
	$self->discard_entry($entry);
	$main::NumberActive -= 1;
	main::LoadItUp();
	return undef;
}

# on_return gets called whenever a connection (or its callback)
# returns EOF (or any other terminating status code available for
# callback functions)
sub on_return {
	my ($self, $request, $response, $entry) = @_;
	&LoadWorm::slave_unit(1, $request, $response);
	unless ( $response->code == 401 )  # "Authorization Required" needs to repeat the request, with this $entry.
   {
      $self->discard_entry($entry);
   	$main::NumberActive -= 1;
	   main::LoadItUp();
   }
	return undef;
}
}

package main;


my @sessions;



#use CGI qw(:standard);
use Time::Local;

use HTTP::Request;

# persistent robot rules support. See 'perldoc WWW::RobotRules::AnyDBM_File'
require WWW::RobotRules::AnyDBM_File;

use FileHandle;
#use File::Path;
use File::Copy;
use HTTP::Date qw(str2time);

use Socket;
use Sys::Hostname;

use Symbol;
sub SetUpSockets;
sub GetNewInstructions;
sub SetUpNewSession;

use LWP::Debug qw(-);

my $NextSecond = LoadWorm->GetTickCount();
my $PerSecond = 0;
my $ActualPerSecondStart = LoadWorm->GetTickCount();
my $ActualPerSecondCount = 0;
my $ReStart;


##################### ##################### ##################### ##################### 
##################### ##################### ##################### ##################### 
# THIS IS THE MAIN FUNCTION
# THIS IS THE MAIN FUNCTION
# THIS IS THE MAIN FUNCTION
#
	$| = 1; # "piping hot".
	$ENV{PERL} = "C:/Perl" unless $ENV{PERL};
	$ENV{LOADWORM} = "./" unless $ENV{LOADWORM};
	
	$I_AM = "unknown";
	$MI_LLAMA_ES = $LoadWorm::HostName;

	$MASTERNAME = $ARGV[0];
	unless ( $MASTERNAME )
	{
		print "Host-ID of SlaveMaster? ";
		$MASTERNAME = <STDIN>;
		chomp $MASTERNAME;
#		$MASTERNAME = "localhost:9676" unless $MASTERNAME;
	}
	$MASTERNAME = "192.168.1.$MASTERNAME:9676" unless ( $MASTERNAME =~ /[.:]/ );

##################### ##################### ##################### ##################### 
# THIS IS THE MAIN LOOP
	while ( 1 ) {
		$ReStart = 0;
		SetUpNewSession;
	
		# Here we loop, letting GetNewInstructions() and myRobot do all the work.
		while ( ! $ReStart ) {
			$pua->wait();
			LoadItUp();
		}
	}
# THIS WAS THE MAIN LOOP
##################### ##################### ##################### ##################### 
#
# THAT WAS THE MAIN FUNCTION
# THAT WAS THE MAIN FUNCTION
# THAT WAS THE MAIN FUNCTION
##################### ##################### ##################### ##################### 
##################### ##################### ##################### ##################### 





#
# Check the URL / content for validation, return non-zero for "do not traverse".
# This validation is done with a custom validation function specified in [Validation].
#
#sub IsCheckedURL { my($Link, $response) = @_;
#	my ($rtn) = 1;

#	for ( keys %Validations )
#	{
#		if ( $Link =~ /$_/ )
#		{
#			$pckt = $Validations{$_};
#			open TMP, ">tempfile_$$";
#			print TMP $response->content;
#			close TMP;
#			unless ( eval "&$pckt(\'$Link\',tempfile_$$)" ) {
#				print "Traversal terminated by $pckt\n";
#				$rtn = 0;
#			}
#			unlink "tempfile_$$";
#		}
#	}
#	return $rtn;
#}

# STUB FOR main::Check()
#sub Check { my ($Link, $Content) = @_;
#	print "Hello from AnyURL::Check!\n";
#	push @{ $main::AlreadyVisited{$Link} }, "I thought I\'d just throw this one in, just for the heck of it!";
#	1; # Normal, "continue", return.
#}





# Pipe the commands from the SlaveMaster down to the slaves, or process
# those commands from the SlaveMaster, depending on our parentage!
sub ProcessNewInstructions {

	for ( @_ )
	{
		$_ = "RESTART" unless $_;
		
		/^REPORT/ && do
		{
			my $actualTime = - $ActualPerSecondStart;
			$ActualPerSecondStart = LoadWorm->GetTickCount();
			$actualTime += $ActualPerSecondStart; # so $actualTime = $Now - $ActualPerSecondStart.
			$actualAve = ($ActualPerSecondCount*1000) / $actualTime if $actualTime;
			$ActualPerSecondCount = 0;
			print MASTER "REPORT $I_AM $TotalDone $TotalTime $RunningSlaves $actualAve\n";
			$TotalDone = 0;
			$TotalTime = 0;
			next;
		};

		/^YOU_ARE=(.+)/ && do
		{	
			$I_AM = $1; mkdir $I_AM, 0666;
			open TIMING, ">$I_AM/timings";
			my $start = LoadWorm->GetTickCount();
			print "Slave $I_AM is born!\n";
			print MASTER "I_AM $I_AM $MI_LLAMA_ES\n";
			next;
		};
		
		# The "SlaveMaster" version.
		/^PROXY=(.+)/ && do
		{
			@Proxy = ();
			push @Proxy, $1;
			next;
		};
		
		/^NOPROXY=(.+)/ && do
		{
			push @NoProxy, $1;
			next;
		};
		
		/^TIMEOUT=(.+)/ && do
		{
			$TimeOut = $1;
			next;
		};

		/^RANDOM=(.+)/ && do { $Randomly = $1; next; };

		/^PAUSE/ && do { $Pause = 1; next; };
		
		/^VERBOSE=(.+)/ && do
		{
			$Verbose = $1;
			next;
		};

		/^TRACE=(.+)/ && do
		{
			$Trace = $1;
			next;
		};

		/^GO=?(.*)$/ && do
		{
			$pua->proxy(http  => $Proxy[0]) if $Proxy[0];
			$pua->no_proxy(@NoProxy);
			$pua->timeout($TimeOut);
			$Pause = 0;
			next;
		};

		/^HARVEST=?(.*)$/ && do
		{
			if ( $1 eq 'GIMME' )
			{
				close TIMING;
				open TMP, "<$I_AM/timings";
				while ( <TMP> ) {
					print MASTER "HARVEST $I_AM $_";
				}
				close TMP;
				print MASTER "HARVEST $I_AM CLOSE\n";
				open TIMING, ">$I_AM/timings";
				next;
			}
			else
			{
				$Harvesting = $1;
			}
			next;
		};

		/^CREDENTIALS=?(.*)$/ && do
		{
			my ($netloc, $realm, $userid, $password) = split /,/, $1;
			$pua->credentials($netloc, $realm, $userid, $password);
			next;
		};
		
		/^VISITS (\d+) (.+)/ && do
		{
			$Visits[$1] = $2;
			$NumOfVisits += 1;
			next;
		};
		
		
		/^SLAVES=(.*)/ && do
		{
			$RunningSlaves = $1;
			$RunningSlaves = $LoadWorm::MaxSockets if $RunningSlaves > $LoadWorm::MaxSockets;
			$NumberAllocated = $RunningSlaves;
			$PerSecond = 0;
			print MASTER "TEXT $I_AM $RunningSlaves at once!\n";
			next;
		};

		/^RESTART$/ && do
		{
			print "SlaveMaster restarting $I_AM\n";

			# Clean up after this session.
			vec($SocketsVector, fileno(MASTER), 1) = 0;
			close MASTER;
			close TIMING;
			$pua->wait();
			$b = unlink "$I_AM/*.*";
   		print "$b files deleted.\n";
   		$b = rmdir "$I_AM";
   		print "$b directory deleted.\n";
#			open TMP, '>newsession.txt'; # This will cause loadslave.bat to start a new session.
#			close TMP;
			$ReStart = 1;
         next;
		};
		
		/^SUICIDE/ && do
		{
			close TIMING;
			close MASTER;
			$pua->wait();
			print "SlaveMaster suicide $I_AM $MI_LLAMA_ES\n";
		
			unlink 'newsession.txt'; # This prevents loadslave.bat from starting a new session.
			$b = unlink "$I_AM/timings";
			print "$b files deleted.\n";
			$b = rmdir "$I_AM";
			print "$b directory deleted.\n";
			exit 1; # WinNT apparently doesn't return exit codes.
		};

		# default;
		print "Warning: unrecognized slave option: $_\n";
		$error = 1;
	}
}




# Set up a socket listener, listening for the Slaves.
sub SetUpSockets { my($mastername) = @_;
	my($remote, $port, $iaddr, $paddr, $proto, $rslt);

	$| = 1;
	
	# For communicating with the LoadMaster, we will use socket MASTER.
	$mastername =~ /(.+):(\d*)/;
	$remote = $1;
	$port = $2;
	if ( $port =~ /\D/ ) { $port = getservbyname($port, 'tcp') }
	die "No port" unless $port;
	print "Connecting to $remote at port $port\n";

	$iaddr = inet_aton($remote) or die "no host: $!";
	$paddr = sockaddr_in($port, $iaddr);

	$proto = getprotobyname('tcp');
	$rslt = socket(MASTER, PF_INET, SOCK_STREAM, $proto) or die "socket: $!";
	while ( not connect(MASTER, $paddr) )
	{
		print "Waiting for LoadMaster on $remote:$port\n";
		sleep 5;
#		or die "connect: $!";
	}
	select (MASTER); $| = 1; select(STDOUT);
	vec($SocketsVector, fileno(MASTER), 1) = 1;
}


sub GetNewInstructions {
my $rin, $ein;
	while ( select($rin=$SocketsVector, undef, $ein=$SocketsVector, 0) ) {
		if ( vec($ein, fileno(MASTER), 1) ) {
			$instruction = "RESTART";
			ProcessNewInstructions($instruction);
			$ReStart = 1;
		}
		if ( vec($rin, fileno(MASTER), 1) ) {
			$instruction = <MASTER>;
			ProcessNewInstructions($instruction);
		}
	}
	return $ReStart;
}






############################################################################################
############################################################################################

sub SetUpNewSession {
	SetUpSockets($MASTERNAME);

	srand(time() ^ ($$ + ($$ * 2**15)) );

	@Visits = {};
	$NumOfVisits = 0;

	$NextVisit = 0;
	$Pause = 0;
	$Pace = 10;
	$NextPace = 0;
	$RotateSlave = 0;
	$Randomly = 0;
	$Verbose = 1;
	$NumberAllocated = 0;
	$RunningSlaves = 0;


####################### LIFTED DIRECTLY FROM TestScript.pl OF ParallelUA.pm ###############
# establish persistant robot rules cache. See WWW::RobotRules for
# non-premanent version. you should probably adjust the agentname
# and cache filename.
#
$rules = new WWW::RobotRules::AnyDBM_File 'ParallelUA', 'cache';

# create new UserAgent (actually, a Robot)
$pua = new myRobot ("LoadSlave", 'glenn@savesmart.com', $rules);
# general ParallelUA settings
$pua->in_order  (0);  # do not handle requests in order of registration
$pua->duplicates(0);  # do not ignore duplicates
$pua->timeout   (30); # in seconds
$pua->redirect  (1);  # do follow redirects AND CREDENTIAL CHALLENGES ! ! ! !
# RobotPUA specific settings
$pua->delay (0);			# in seconds
$pua->max_req  ($LoadWorm::MaxSockets);	# max parallel requests per server
$pua->max_hosts(10);		# max parallel servers accessed
$pua->use_alarm(0); # no alarm on NT ?
#
####################### WAS LIFTED DIRECTLY FROM TestScript.pl OF ParallelUA.pm ###########
}



############################################################################################
############################################################################################

sub handle_answer {
    my ($content, $response, $protocol, $entry) = @_;

	 if ( $Verbose > 1 ) {
		 print "Handling answer from '",$response->request->url,": ",
          length($content), " bytes, Code ",
          $response->code, ", ", $response->message,"\n";
	 }
    if (length ($content) ) {
	# just store content if it comes in
	$response->add_content($content);
    } else {
	# our return value determins how ParallelUA will continue:
	# We have to import those constants via "qw(:CALLBACK)"!
	# return C_ENDCON;  # will end only this connection
			    # (silly, we already have EOF)
	# return C_LASTCON; # wait for remaining open connections,
			    # but don't issue any new ones!!
	# return C_ENDALL;  # will immediately end all connections
			    # and return from $pua->wait
    }
    # ATTENTION!! If you want to keep reading from your connection,
    # you should currently have a final 'return' statement here.
    # Sometimes ParallelUA will cut the connection if it doesn't
    # get it's "undef" here. (that is, unless you want it to end, in
    # which case you should use the return values above)
    return;		    # just keep on connecting/reading/waiting
}






############################################################################################
############################################################################################
sub LoadItUp {

	return unless $NumOfVisits;
	return if $Pause or $ReStart;

	unless ( $PerSecond > 0 ) {
		return if ( LoadWorm->GetTickCount() < $NextSecond );
		$NextSecond += 1000;
		$PerSecond = $RunningSlaves;
  }

	while ( $NumberActive < $NumberAllocated and $PerSecond > 0 )
	{
		$PerSecond -= 1;
      $ActualPerSecondCount += 1;
		if ( $Verbose > 2 ) {
			print "Registering $Visits[$NextVisit]\n";
		}
		my $request = HTTP::Request->new('GET', $Visits[$NextVisit]);
		if ( &LoadWorm::slave_unit(0, $request, undef) )
		{
			# register requests
		
			# we register each request with a callback here, although we might
			# as well specify a (variable) filename here, or leave the second
			# argument blank so that the answer will be stored within the
			# response object (see $pua->wait further down)
			if ( $res = $pua->register ($request, \&handle_answer) )
			{
			# some requests will produce an error right away, such as
			# request featuring currently unsupported protocols (ftp,
			# gopher) or requests to server that failed to respond during
			# an earlier request.
			# You can examine the reason for this right away:
				print STDERR $res->error_as_HTML;
			# or simply ignore it here. Each request, even if it failed to
			# register properly, will show up in the final list of
			# requests returned by $pua->wait, so you can examine it
			# later. If you have overridden the 'on_failure' method of
			# ParallelUA or RobotPUA, it will be called if your request
			# fails.
			}
			else {
				$NumberActive += 1;
			}
		}
		if ( $Randomly ) {
			$NextVisit = int(rand $NumOfVisits);
		}
		else
		{
			$NextVisit += 1;
			if ( $NextVisit >= $#Visits ) {
				$NextVisit = 0;
			}
		}
	}
}



############################################################################################
############################################################################################
{
#	package LWP::ParallelUA;
package LWP::Parallel::UserAgent;

	# THIS IS TIGHTLY BASED ON LWP::ParallelUA->wait.  CHANGES ARE MARKED BY
	# gdw 12.sep.97 begin
	#    (here are my changes)
	# gdw 12.sep.97 end
	
   sub wait {
  my ($self, $timeout) = @_;
  LWP::Debug::trace("($timeout)");

  my $foobar;

  $timeout = $self->{'timeout'} unless defined $timeout;

  # shortcuts to in- and out-filehandles
  my $fh_out = $self->{'select_out'};
  my $fh_in  = $self->{'select_in'};
  # gdw 12.sep.97 begin
  $fh_in->add(fileno(main::MASTER)) if fileno(main::MASTER) and $main::ReStart == 0;
  # gdw 12.sep.97 end
  my $fh_err;			# ignore errors for now
  my @ready;

  my ($active, $pending);
 ATTEMPT:
  while ( $active = scalar keys %{ $self->{'current_connections'} }  or
  # gdw 12.sep.97 begin
	  fileno(main::MASTER) or
  # gdw 12.sep.97 end
	  $pending = scalar ($self->{'handle_in_order'}?
			     @{ $self->{'ordpend_connections'} } :
			     keys %{ $self->{'pending_connections'} } ) ) {
	 # check select
	 if ( (scalar $fh_in->handles) or (scalar $fh_out->handles) ) {
      LWP::Debug::debug("Selecting Sockets, timeout is $timeout seconds");
$fh_err = $fh_in;
      unless ( @ready = IO::Select->select ($fh_in, $fh_out, $fn_err, $timeout) ) {
	#
	# empty array, means that select timed out
	LWP::Debug::trace('select timeout');
  # gdw 12.sep.97 begin
	$main::NumberActive = 0;
  # gdw 12.sep.97 end
	last ATTEMPT;
      } else {
	# something is ready for reading or writing
	my ($ready_read, $ready_write, $error) = @ready;
	my ($entry, $socket);
if ( scalar @{$error} ) {warn "socket error(s) ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! $!";}
	#
	# ERROR QUEUE
	#
	foreach $socket (@$error) {
		# gdw 12.sep.97 begin
		if ( $socket == fileno(main::MASTER) ) {
			main::LoadItUp();
			if ( main::GetNewInstructions() ) {
				$main::NumberActive = 0;
				last ATTEMPT;
			}
			next;
		}
	}
	# gdw 12.sep.97 end
	#
	# WRITE QUEUE
	#
	foreach $socket (@$ready_write) {
	  LWP::Debug::debug('Writing to Sockets');
	  $entry = $self->{'entries_by_sockets'}->{$socket};
	
	  my ( $request, $protocol, $fullpath, $arg ) =
	    $entry->get( qw(request protocol fullpath arg) );
	  my ($listen_socket, $response) =
	    $protocol->write_request ($request,
				      $socket,
				      $fullpath,
				      $arg,
				      $timeout);
	  if ($response) {
	    $entry->response($response);
	    LWP::Debug::trace('Error while issuing request '.
			      $request->url->as_string)
	      unless $response->is_success;
	  }
	  # one write is (should be?) enough
	  delete $self->{'entries_by_sockets'}->{$socket};
	  $fh_out->remove($socket);
	  if (ref($listen_socket)) {
	    # now make sure we start reading from the $listen_socket:
	    # file existing entry under new (listen_)socket
	    $fh_in->add ($listen_socket);
	    $entry->listen_socket($listen_socket);
	    $self->{'entries_by_sockets'}->{$listen_socket} = $entry;
	  } else {
	    # remove from current_connections
	    $self->_remove_current_connection ( $entry );
	  }
	}
	
	#
	# READ QUEUE
	#
	foreach $socket (@$ready_read) {
		# gdw 12.sep.97 begin
		if ( $socket == fileno(main::MASTER) ) {
			main::LoadItUp();
			if ( main::GetNewInstructions() ) {
				$main::NumberActive = 0;
				last ATTEMPT;
			}
			next;
		}
	# gdw 12.sep.97 end
		LWP::Debug::debug('Reading from Sockets');
	  $entry = $self->{'entries_by_sockets'}->{$socket};
	  my ( $request, $response, $protocol, $fullpath, $arg, $size) =
	    $entry->get( qw(request response protocol
			    fullpath arg size) );
	
	  my $retval =  $protocol->read_chunk ($response, $socket, $request,
					       $arg, $size, $timeout,
					       $entry);
	
	  # examine return value. $retval is either a positive
	  # number, indicating the number of bytes read, or
	  # '0' (for EOF), or a callback-function code (<0)
	
	  LWP::Debug::debug ("'$retval' = read_chunk from $entry (".
			     $request->url.")");
	
	  # call on_return method if it's the end of this request
	  unless ($retval > 0) {
	    my $command = $self->on_return ($request, $response, $entry);
	    $retval = $command  if $command < 0;
	
	    LWP::Debug::debug ("'$command' = on_return");
	
	  }
	  if ($retval > 0) {
	    # In this case, just update response entry
	    # $entry->response($response);
	  } else { # numeric, that means: EOF, C_LASTCON, or C_ENDCON}
	    # read_chunk returns 0 if we reached EOF
	    $fh_in->remove($socket);
	    # use protocol dependent method to close connection
	    $protocol->close_connection($response, $socket,
					$request, $entry->cmd_socket);
close $socket;
	    $socket = undef; # close socket
	    # remove from current_connections
	    $self->_remove_current_connection ( $entry );
	    # handle redirects and security if neccessary
	
	    if ($retval eq C_ENDALL) {
	      # should we clean up a bit? Remove Select-queues:
	      $self->{'select_in'} = new IO::Select;
	      $self->{'select_out'} = new IO::Select;
	      return $self->{'entries_by_requests'};
	    } elsif ($retval eq C_LASTCON) {
			# just delete all pending connections
	      $self->{'pending_connections'} = {};
	      $self->{'ordpend_connections'} = [];
	    } else {
	      if ($entry->redirect_ok) {
		$self->handle_response ($entry);
	      }
	      # pop off next pending_connection (if bandwith available)
	      $self->_make_connections;
	    }
	  }
	}
      }				# of unless (@ready...) {} else {}

    } else {
      # when we are here, can we have active connections?!!
      #(you might want to comment out this huge Debug statement if
      #you're in a hurry. Then again, you wouldn't be using perl then,
      #would you!?)
      LWP::Debug::trace("\n\tCurrent Server: ".
			scalar (keys %{$self->{'current_connections'}}) .
			" [ ". join (", ",
			  map { $_, $self->{'current_connections'}->{$_} }
			  keys %{$self->{'current_connections'}}) .
			" ]\n\tPending Server: ".
			($self->{'handle_in_order'}?
			 scalar @{$self->{'ordpend_connections'}} :
			 scalar (keys %{$self->{'pending_connections'}}) .
			 " [ ". join (", ",
			  map { $_,
			       scalar @{$self->{'pending_connections'}->{$_}} }
			       keys %{$self->{'pending_connections'}}) .
			 " ]") );
    } # end of if $sel->handles
    # try to make new connections
    $self->_make_connections;
  } # end of while 'current_connections' or 'pending_connections'
  # should we delete fh-queues here?!
  # or maybe re-initialize in case we register more requests later?
  # in that case we'll have to make sure we don't try to reconnect
  # to old sockets later - so we should create new Select-objects!
  $self->{'select_in'} = new IO::Select;
  $self->{'select_out'} = new IO::Select;

  # allows the caller quick access to all issued requests,
  # although some original requests may have been replaced by
  # redirects or authentication requests...
  return $self->{'entries_by_requests'};
}

}






# This is a actually functioning login line: id from home.get (not zero!), ad= and pw= as appropriate.
# http://borris.savesmart.com:80/MXTEST/owa/home.get?ad=joe&pw=hoe&Login.x=1&Login.y=1&id=9459&nav=
{
	package LoadWorm;
use strict;

sub slave_unit {
	my ($mode, $request, $response) = @_;

	if ( $mode == 0 ) {
		my $url_in = $request->url;
		if ( $url_in =~ /Login/ ) {
			$url_in =~ s/ad=[^&]*/ad=sam@/;
			$url_in =~ s/pw=[^&]*/pw=spade/;
		}
		if ( scalar(@sessions) )
		{
			my $id = shift @sessions;
			push @sessions, $id;
			$url_in =~ s/id=(\d*)/id=$id/;
			$request->url($url_in);
		}
		return 1;
	}
	elsif ( $mode == 1 ) {
		ReportSuccess($mode, $request, $response);
		# the home.get (no parameters) URL creates a session id.
		if ( $request->url =~ /home.get$/ ) {
			if ( scalar(@sessions) < $main::NumberAllocated ) {
				# yank the new session id out of the response content.
				$response->content =~ m/id=(\d+)/;
print "SESSION $1 STARTED\n";
				push @sessions, $1 if $1;
			}
		}
	}
	elsif ( $mode == 2 ) {
		ReportSuccess($mode, $request, $response);
	}
}


sub ReportSuccess {
	my ($mode, $request, $response) = @_;
my $finish = LoadWorm->GetTickCount();
my $start = $request->{'_start_systime'};
	if ( $finish < $start ) # handle the wraparound at 49.7 days.
	{
		$start -= 9999999;
		$finish -= 9999999;
	}
	my $difftime = $finish - $start;
	if ( $mode == 2 ) {
		if ( $main::Harvesting ) {
			print main::TIMING "F:$finish ",$request->url,"\n";
			print main::TIMING $response->code,"\n";
			print main::TIMING $response->message,"\n";
			print main::TIMING "X:$finish ",$request->url,"\n";
		}
		if ( $main::Verbose ) {
			print "\nFAIL  ".$request->url."\nFAIL  ".$response->code." ".$response->message."\n\n";	
		}
	} else {
		$main::TotalDone += 1;
		$main::TotalTime += $difftime;
		print main::TIMING "S:$finish ",$request->url,"\n" if ( $main::Harvesting );
		if ( $main::Verbose ) {
			print "DONE  ".$difftime." ms ".$request->url."\n";
			print "CODE ".$response->code." ".$response->message."\n";
		}
	}
}

}

