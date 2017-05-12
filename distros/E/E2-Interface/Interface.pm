# E2::Interface
# Jose M. Weeks <jose@joseweeks.com>
# 07 August 2003
#
# See bottom for pod documentation.

package E2::Interface;

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = "0.34";

# This module also require()s the following modules in the body of
# certain methods (threading loads faster this way than with use.
# 	XML::Twig
# 	LWP::UserAgent;
#	HTTP::Request::Common qw(GET HEAD POST);
#	HTTP::Cookies;
#	URI::Escape;
#	E2::Ticker;

# Threading, if supported

eval "
	use threads;
	use threads::shared;
	use Thread::Queue;
";
our $THREADED = !$@;

# Unicode

eval "
	use Encode;
";
our $ENCODED = !$@;

our $DEBUG	= 0;	# Debug info: set to 1 for basic debug info,
			#             2 to add a message for each sub,
			#             3 to add data dumping

# Get OS string

our $OS_STRING;

BEGIN {
	if( -x '/bin/uname' ) {
		$OS_STRING = `/bin/uname -srmo`;
		chomp( $OS_STRING );
	} else {
		$OS_STRING = $^O;
		if( $OS_STRING eq 'MSWin32' ) {
			my $s;
			eval "use Win32";
			if( !$@ ) {
				$s = join ' ', &Win32::GetOSName;
			}

			$OS_STRING = $s		if $s;
		}
	}
}

sub new;
sub clone;

sub login;
sub verify_login;
sub logout;
sub process_request;

sub domain;
sub cookie;
sub parse_links;
sub document;
sub logged_in;
sub agentstring;

sub version;
sub client_name;
sub debug;

sub this_username;
sub this_user_id;

sub decode_xml;

sub use_threads;
sub job_id;
sub thread_then;
sub finish;

# Private

sub start_job;
sub extract_cookie;
sub post_process;
sub process_request_raw;

################################################################################
# Class methods
################################################################################

sub version	{ return $VERSION }
sub client_name	{ return "e2interface-perl" }
sub decode_xml	{
	my( undef, $s ) = @_;
	return $s if !$ENCODED;
	return decode_utf8($s) || $s;
}

sub debug {
	my (undef, $d) = @_;

	if( $d && !$DEBUG ) {

		# Print e2interface info

		print '-' x 80 . "\n";
		print &client_name . '/' . &version . 
			" by Jose M. Weeks <jose\@joseweeks.com> (Simpleton)\n";
		printf "Perl v%vd", $^V;
		print "; $OS_STRING;" . ' Threads ' . 
			($THREADED ? '' : 'UN' ) . "AVAILABLE\n";
		print '-' x 80 . "\n";
	}

	$DEBUG = $d;
}

sub new {
	my $arg = shift;
	my $class = ref( $arg ) || $arg;
	my $self = {};

	warn "Creating $class object"		if $DEBUG > 1;

	# All of these are references so that we can clone()
	# copies and any changes after the cloning affect all
	# clones.

	$self->{this_username}	= \(my $a = 'Guest User');
	$self->{this_user_id}	= \(my $b);
	
	$self->{agentstring}	= \(my $c);
	$self->{cookie}		= \(my $d);

	$self->{parse_links}	= \(my $e);
	$self->{domain}		= \(my $f = "everything2.com" );

	$self->{threads}	= \(my $ta);
	$self->{next_job_id}	= \(my $tb = 1);
	$self->{job_to_thread}	= \(my $tc);
	$self->{post_commands}	= \(my $td);
	$self->{final_commands} = \(my $te);
	$self->{finished}	= \(my $tf);
	
	return bless $self, $class;
}

################################################################################
# Object Methods
################################################################################

sub clone {
	my $self  = shift	or croak "Usage: clone E2INTERFACE_DEST, E2INTERFACE_SRC";
	my $src   = shift	or croak "Usage: clone E2INTERFACE_DEST, E2INTERFACE_SRC";

	warn "E2::Interface::clone\n"		if $DEBUG > 1;

	$self->{agentstring} 	= $src->{agentstring};
	$self->{this_username}	= $src->{this_username};
	$self->{this_user_id}	= $src->{this_user_id};
	$self->{parse_links}	= $src->{parse_links};
	$self->{domain}		= $src->{domain};
	$self->{cookie}		= $src->{cookie};
	$self->{threads}	= $src->{threads};
	$self->{next_job_id}	= $src->{next_job_id};
	$self->{job_to_thread}	= $src->{job_to_thread};
	$self->{post_commands}	= $src->{post_commands};
	$self->{final_commands}	= $src->{final_commands};
	$self->{finished}	= $src->{finished};
	
	return $self;
}

sub login {
	my $self = shift		or croak( "Usage: login E2INTERFACE, USERNAME, PASSWORD" );
	my $username = shift 		or croak( "Usage: login E2INTERFACE, USERNAME, PASSWORD" );
	my $password = shift		or croak( "Usage: login E2INTERFACE, USERNAME, PASSWORD" );

	warn "E2::Interface::login\n"		if $DEBUG > 1;

	require E2::Ticker;

	return $self->thread_then(
		[ 
			\&process_request,
			$self,
			op   => 'login',
			user => $username,
			passwd => $password,
			node => $E2::Ticker::xml_title{session}
		],
	sub {
		my $xml = shift;

		if( $xml =~ /<currentuser .*?user_id="(.*?)".*?>(.*?)</s ) {
			${$self->{this_username}} = $2;
			${$self->{this_user_id}}  = $1;
		} else {
			croak "Invalid document";
		}

		return $self->cookie && 1;	
	});
}

sub verify_login {
	my $self = shift;
	
	require E2::Ticker;

	warn "E2::Interface::verify_login\n"	if $DEBUG > 1;

	return undef	if !$self->logged_in;

	return $self->thread_then(
		[
			\&process_request,
			$self,
			node => $E2::Ticker::xml_title{session}
		],
	sub {
		my $xml = shift;
	
		if( $xml =~ /<currentuser .*?user_id="(.*?)".*?>(.*?)</s ) {
			${$self->{this_username}} = $2;
			${$self->{this_user_id}}  = $1;
		} else {
			croak "Invalid document";
		}

		return $self->cookie && 1;
	});
}

sub logout {
	my $self = shift 	or croak "Usage: logout E2INTERFACE";

	warn "E2::Interface::logout\n"		if $DEBUG > 1;

	$self->cookie( undef );
	${$self->{this_username}} = 'Guest User';
	${$self->{this_user_id}}  = undef;

	return 1;
}

sub process_request {
	my $self = shift 
		or croak "Usage: process_request E2INTERFACE, [ ATTR => VAL [ , ATTR2 => VAL2 , ... ] ]";
	my %pairs = @_
		or croak "Usage: process_request E2INTERFACE, [ ATTR => VAL [ , ATTR2 => VAL2 , ... ] ]";

	warn "E2::Interface::process_request\n"		if $DEBUG > 1;

	# If we're dealing with threads, send a process_request message

	if( ${$self->{threads}} ) {
		return $self->start_job(
			'POST',
			'http://' . $self->domain . '/',
			$self->cookie,
			${$self->{agentstring}},
			($self->parse_links ? () : (links_noparse => 1)),
			%pairs
		);
	}

	# Otherwise, just process the request

	my $response = process_request_raw(
				'POST',
				'http://' . $self->domain . '/', 
				$self->cookie,
				${$self->{agentstring}},
				($self->parse_links?():(links_noparse => 1)),
				%pairs
		       );

	my $c = extract_cookie( $response );
	$self->cookie( $c )	if $c;

	return $self->{last_document} = post_process( $response );
}

sub this_username {
	my $self = shift	or croak "Usage: this_username E2INTERFACE";
	return ${$self->{this_username}};
}

sub this_user_id {
	my $self = shift	or croak "Usage: this_user_id E2INTERFACE";
	return ${$self->{this_user_id}};
}

sub logged_in {
	my $self = shift	or croak "Usage: logged_in E2INTERFACE";

	return ${$self->{cookie}} && 1;
}

sub domain {
	my $self = shift     or croak "Usage: domain E2INTERFACE [, DOMAIN ]";
	
	${$self->{domain}} = $_[0]	if $_[0];
	
	return ${$self->{domain}};
}

sub cookie {
	my $self = shift  or croak "Usage: cookie E2INTERFACE [, COOKIE ]";

	if( @_ ) {
		${$self->{cookie}} = $_[0];

		if( $_[0] =~ /(.*?)%257C/ ) {
			${$self->{this_username}} = $1;
		}
	}

	return ${$self->{cookie}};
}

sub agentstring {
	my $self = shift  or croak "Usage: agentstring E2INTERFACE [, STRING ]";

	${$self->{agentstring}} = $_[0]	if @_;

	return ${$self->{agentstring}};
}

sub parse_links {
	my $self = shift  or croak "Usage: parse_links E2INTERFACE [ , BOOL ]";

	${$self->{parse_links}} = $_[0]	if @_;

	return ${$self->{parse_links}};
}

sub document {
	my $self = shift  or croak "Usage: xml E2INTERFACE";

	return $self->{last_document};
}

sub parse_twig {
	if( @_ != 3 ) { croak "Usage: parse_twig E2INTERFACE, XML, HANDLERS"; }
	my ( $self, $xml, $handlers ) = @_;
	
	require XML::Twig;

	warn "E2::Interface::parse_twig\n"	if $DEBUG > 1;

	my $twig = new XML::Twig(
#		keep_encoding => 1, 
		twig_handlers => $handlers
	);

	# If we're using a version of perl that allows us to do it, make sure
	# the string is in perl's internal representation, then encode into
	# UTF8.

	if( $ENCODED ) {
		$xml = decode_utf8( $xml ) || $xml;
		$xml = encode_utf8( $xml );
	} 

	if( !$twig->safe_parse( $xml, ProtocolEncoding => 'UTF-8' ) ) {
		chomp $@;
		croak "Parse error: $@";
	}
}

################################################################################
#
# Threading in e2interface.
#
# (The background thread)
# 
#	1: thread_then creates NUM background threads (sub _thread), each
#	   with its own input and output queue
#	2: each _thread waits for a two value list on its input queue:
#		a. job_id
#		b. reference to a list identical to the parameter list to
#		   process_request_raw
#	3: each _thread calls process_request_raw, then calls extract_cookie
#	   and post_process on the response, and returns the following on
#	   it output queue:
#	   	a. job_id
#	   	b. reference to a hash with the following keys:
#	   		exception - exception string: only defined on exception
#	   		cookie    - the return value of extract_cookie
#	   		text      - the return value of post_process
#
# (The main thread) -- (these bubble upward from the lowlevel methods, so
#                       this mainly ordered backward, but follows the return
#                       values upward)
#
#	1: start_job takes the same parameters as process_request_raw. It
#	   passes this list off to the first convenient background thread
#	   and stores the job_id -> thread mapping. It returns (-1, job_id)
#	2: process_request, if threading has been enabled, calls start_job
#	   and returns (-1, job_id)
#	3: thread_then takes two code references as parameters. It calls the
#	   first code reference.
#	   	a. if this reference returns (-1,job_id), it stores the second
#		   reference to be executed when that first one finishes,
#		   and to be passed its return value as its parameters.
#		   This allows thread_then to be chained, each return value
#		   passed to the next stored code reference.
#		b. If this reference returns anything else, it passes this
#		   value directly to the second code reference and then
#		   returns the subsequent return value.
#	   in effect, thread_then allows code to be executed regardless of
#	   whether or not it calls a method that gets passed to a background
#	   thread.
#	4: finish checks the output queue of the background threads. If
#	   the specified job hasn't finished yet, it returns (-1, job_id).
#	   If it has finished, finish executes any stored code references
#	   (those that thread_then stored). It returns the return value of
#	   the final stored code reference.
#
################################################################################

sub use_threads {
	my $self = shift   or croak "Usage: use_threads E2INTERFACE [ COUNT ]";
	my $count = shift || 1;

	warn "E2::Interface::use_threads\n"	if $DEBUG > 1;

	if( ! $THREADED ) {
		warn "Unable to use_threads: ithreads not available" if $DEBUG;
		return undef;
	}

	if( $count < 1 ) {
		warn "Unable to use_threads: invalid number $count"  if $DEBUG;
		return undef;
	}

	if( ${$self->{threads}} ) {
		warn "Unable to use_threads: threads already in use" if $DEBUG;
		return undef;
	}

	warn "Threading enabled (using $count thread" . 
		($count > 1 ? 's' : '') . ")\n"		if $DEBUG;

	${$self->{threads}} = [];
	for( my $i = 0; $i < $count; $i++ ) {
		my %t = (
			to_q	=> Thread::Queue->new,
			from_q	=> Thread::Queue->new,
		);
		
		$t{thread} = threads->create(
			\&_thread,
			$t{to_q},
			$t{from_q}
		);

		if( ! $t{thread} ) {
			croak "Unable to create thread";
		}

		push @{${$self->{threads}}}, \%t;
	}

	return 1;

	# _thread( INPUT_QUEUE, OUTPUT_QUEUE )

	sub _thread {
		my $from_q = shift;
		my $to_q   = shift;
		my $id;

		warn "Spawned new thread\n"	if $DEBUG;

		while( $id = $from_q->dequeue ) {
			my $req = $from_q->dequeue;
			my $resp;
			my %r : shared;

			warn "Processing job $id"	if $DEBUG > 1;

			eval { $resp = process_request_raw( @$req ) };
			if( $@ ) {
				$r{exception} = $@;
			} else {
				$r{cookie} = extract_cookie( $resp );
				$r{text}   = post_process( $resp );
			}
			
			$to_q->enqueue( $id, \%r );
		}
	}
}

sub join_threads {
	my $self = shift;

	foreach( @{${$self->{threads}}} ) {
		$_->{to_q}->enqueue( 0 );
		$_->{thread}->join;
	}

	# Finish the jobs

	my @r; my @i;
	while( @i = $self->finish ) { push @r, \@i if $i[0] ne "-1" }

	# Dismantle the threading

	${$self->{threads}}		= undef;
	${$self->{next_job_id}}		= undef;
	${$self->{job_to_thread}}	= undef;
	${$self->{post_commands}}	= undef;
	${$self->{final_commands}}	= undef;
	${$self->{finished}}		= undef;

	return @r;
}

sub detach_threads {
	my $self = shift;
	
	foreach( @{${$self->{threads}}} ) {
		$_->{to_q}->enqueue( 0 );
		$_->{thread}->detach;
	}

	# Finish all jobs that are ready to be finished

	my @r; my @i;
	while( @i = $self->finish ) { push @r, \@i if $i[0] ne "-1" }

	# Dismantle the threading

	${$self->{threads}}		= undef;
	${$self->{next_job_id}}		= undef;
	${$self->{job_to_thread}}	= undef;
	${$self->{post_commands}}	= undef;
	${$self->{final_commands}}	= undef;
	${$self->{finished}}		= undef;
	
	return @r;
}

sub thread_then {
	my $self = shift;
	my $cmd  = shift;
	my $post = shift;
	my $final = shift;

	warn "E2::Interface::thread_then\n"	if $DEBUG > 1;
	
#	warn 'Dump of $cmd:' . Dumper( $cmd )	if $DEBUG > 2;
	warn 'Adding post-command'		if $post && $DEBUG > 2;	
	my @response;

	# Run command. If not threaded, run its post command and
	# return

	if( ref $cmd ) {
		my $c = shift @$cmd;
		@response = &$c( @$cmd );
	} else {
		@response = &$cmd( @_ );
	}
	
	if( !$response[0] || $response[0] ne "-1" ) {
		my @r = &$post( @response );
		&$final if $final;
		return ( @r>1 ? @r : $r[0] );
	}

	# If we're here, we called a threaded routine. Add the post
	# command to its caller's list

	warn "Job deferred and assigned id $response[1]"	if $DEBUG > 2;

	push @{${$self->{post_commands}}->{$response[1]}}, $post;
	push @{${$self->{final_commands}}->{$response[1]}}, $final if $final;

	return @response;
}

sub finish {
	my $self = shift;
	my $job = shift;

	my $response;

	warn "E2::Interface::finish\n"		if $DEBUG > 1;
	warn "Job id = $job"			if $DEBUG > 2;

    # What we're going to do here is get a $job (if we haven't been passed
    # one), and get a $response hash for that job. Otherwise, return.

	# If $job is undefined, find the first finished job and return it

	if( ! defined $job ) {

		# Get it off the list of finished jobs, if possible;

		(my $k) = keys %{${$self->{finished}}};
		if( $k ) {
			warn "Job previously finished, returning" if $DEBUG > 2;
			$job = $k;
			$response = delete ${$self->{finished}}->{$k};

		# Otherwise, check all the queues for finished jobs

		} else {
			my $pending = 0; # Count pending jobs, so we know
			                 # whether there are any left or not
			
			for( my $i = 0; $i < @{${$self->{threads}}}; $i++ ) {
				my $t = ${$self->{threads}}->[$i];
				my $pending += $t->{to_q}->pending;	
				my $id = $t->{from_q}->dequeue_nb;

				if( $id ) { # Got one
					$response = $t->{from_q}->dequeue;
					$job = $id;
					last;
				}
			}

			if( ! $response ) {

				# If there are no pending jobs, return a
				# false value. otherwise, return a
				# non-specific deferred value

				if( ! $pending ) {
					return ();
				}

				return (-1, -1);
			}
		}
		
	# Otherwise ($job _is_ defined), so first check to see if
	# we've already pulled this job off the queue.

	} elsif( ${$self->{finished}}->{$job} ) {
		warn "Job previously finished, returning"	if $DEBUG > 2;
		$response = ${$self->{finished}}->{$job};
		delete ${$self->{finished}}->{$job};

	# Otherwise, try to get it off the queue; return a deferred value
	# if we can't.

	} else {
		my $thr = ${$self->{job_to_thread}}->{$job};
		
		warn "Unable to find thread for job $job" if $DEBUG && !$thr;
		
		return () if !$thr;

		while( my $id = $thr->{from_q}->dequeue_nb ) {

			# Get response

			my $r = $thr->{from_q}->dequeue;
		
			warn "Retrieved job $id"	if $DEBUG > 2;

			delete ${$self->{job_to_thread}}->{$id};

			if( $id == $job ) {	# The right job?
				$response = $r;
				last;
			} else {
				# Store for later
				${$self->{finished}}->{$id} = $r;
			}
		}
		
		# Now, if the job is complete, $response will contain
		# a value. If it doesn't, return -1 and set job_id
		# (tell the caller that the command is still deferred).

		if( ! $response ) {
			warn "Deferring job $job"	if $DEBUG > 2;
			return (-1, $job);
		}
	}

    # At this point, we have a valid $job and $response. Do
    # post-processing, exception-handling, etc., and return.

	# If we've received an exception, now is the time to
	# throw it.

	if( $response->{exception} ) {
		
		# Execute any final commands and clear all commands
		
		foreach( @{${$self->{final_commands}}->{$job}} ) { &$_ }
		delete ${$self->{post_commands}}->{$job};
		delete ${$self->{final_commands}}->{$job};
		
		# throw

		die $response->{exception};
	}

	# Now, finish the command and return

	$self->cookie( $response->{cookie} ) if $response->{cookie};

	# Save document

	$self->{last_document} = $response->{text};

	# Execute any post code, passing the return values of one
	# as the parameters of the next
	
	my @param = ( $response->{text} );
	my @ret   = ( $response->{text} );
	
	warn "Executing " . scalar @{${$self->{post_commands}}->{$job}} .
		"post-commands"		if $DEBUG > 2;

	eval {
		while( my $c = shift @{${$self->{post_commands}}->{$job}} ) {
			@ret = &$c( @param );
			@param = @ret;
		}
	};
	my $exc = $@;
	
	# Execute any 'final' commands. These have no return values.

	foreach( @{${$self->{final_commands}}->{$job}} ) { &$_ }
	delete ${$self->{post_commands}}->{$job};
	delete ${$self->{final_commands}}->{$job};

	# If post-processing threw any exceptions, re-throw them

	die $exc if $exc;
	
	return ( $job, @ret );
}

sub start_job {
	my $self = shift;

	warn "E2::Interface::start_job\n"	if $DEBUG > 1;
	
	# Find the first open thread, or the one with the
	# least jobs pending.

	my $min = 9999;
	my $thr = ${$self->{threads}}->[0];

	foreach( @{${$self->{threads}}} ) {
		if( !$_->{to_q}->pending ) {
			$thr = $_;
			last;
		} elsif( $_->{to_q}->pending < $min ) {
			$min = $_->{to_q}->pending;
			$thr = $_;
		}
	}

	# Send the message

	my $job = ${$self->{next_job_id}}++;
	my @job : shared = @_;

	warn "Handing $job off to $thr"		if $DEBUG > 2;

	$thr->{to_q}->enqueue( $job, \@job );

	${$self->{job_to_thread}}->{$job} = $thr;

	return (-1, $job);
}

################################################################################
# Private, non-method subroutines
################################################################################

# Usage: my $cookie = extract_cookie( RESPONSE )
#
# Extracts a cookie from an LWP::UserAgent object.

sub extract_cookie {
	require HTTP::Cookies;

	my $response = shift;
	my $c = HTTP::Cookies->new;

	warn "E2::Interface::extract_cookie\n"		if $DEBUG > 1;
	
	$c->extract_cookies( $response );

	# It seems that the cookie value may or may not be surrounded by
	# quotation marks, so deal with either eventuality.

	$c->as_string =~ /userpass=(.*?);/;
	my $s = $1;
	$s =~ s/^"(.*)"$/$1/ if $s;

	warn "Cookie found: $s"				if $1 && $DEBUG > 2;
	
	return $s;
}

# Usage: $string = post_process STRING
#
# Turns the return value of process_request_raw into a
# string. Fixes encoding as well.

sub post_process {
	my $resp = shift	or croak "Usage: post_process RESPONSE";

	require HTTP::Request;

	warn "E2::Interface::post_process\n"	if $DEBUG > 1;
	
	my $s = $resp->as_string;

	# Strip HTTP headers

	$s =~ s/.*?\n\n//s;

	##### These are workarounds for some of the broken XML that
	##### displaytype=xmltrue outputs due to unescaped text.

	# E2 doesn't properly escape a number of titles in e2links, so
	# do it here....

	my $encode = sub {
		local $_ = shift;
		s/</&lt;/sg;
		s/>/&gt;/sg;
		s/&/amp;/sg;
		return $_;
	};
	
	$s =~ s/(<e2link .*?>)(.*?)(<\/e2link>)/$1 . &$encode($2) . $3/esg;

	# Escape the various entities that have not been escaped

	#my %valid = ( amp => 1, lt => 1, gt => 1 );
	#$s =~ s/\&(\w+?);/$valid{lc($1)} ? "\&$1;" : "\&amp;$1;"/sge;

	# For &, <, and > which haven't been escaped, escape them (if we
	# can be sure they're not valid xml.

#	$s =~ s/\&(?!\w+;)/&amp;/sg;
	#$s =~ s/<(?![\w\/?][^<]*>)/&lt;/sg;
	#$s =~ s/>/($` =~ m-<[\w\/?][^>]*$-s) ? '>' : '&gt;'/sge;

	# Demoronize and return

	return &demoronise($s);
}

sub demoronise {
	local $_ = shift;

	# This has been adapted from a public domain script called
	# demoroniser.pl by John Walker (can be found at
	# http://www.fourmilab.ch/webtools/demoroniser/ ). That script
	# replaced MS "smart quotes" and other nonstandard characters
	# with their plaintext equivalents.
	#
	# I've modified them to convert, instead, to their HTML entity
	# equivalents.
	
	#   Map strategically incompatible non-ISO characters in the
	#   range 0x82 -- 0x9F into plausible substitutes where
	#   possible.

	if( 0 ) { # Convert to html entities
	
		s/\x82/&amp;sbquo;/sg;
		s/\x83/&amp;fnof;/sg;
		s/\x84/&amp;bdquo;/sg;
		s/\x85/&amp;hellip;/sg;
		s/\x86/&amp;dagger;/sg;
		s/\x87/&amp;Dagger;/sg;
		s/\x88/&amp;circ;/sg;
		s/\x89/&amp;permil;/sg;
		s/\x8A/&amp;Scaron;/sg;
		s/\x8B/&amp;lsaquo;/sg;
		s/\x8C/&amp;OElig;/sg;

		s/\x91/&amp;lsquo;/sg;
		s/\x92/&amp;rsquo;/sg;
		s/\x93/&amp;ldquo;/sg;
		s/\x94/&amp;rdquo;/sg;
		s/\x95/&amp;bull;/sg;
		s/\x96/&amp;ndash;/sg;
		s/\x97/&amp;mdash;/sg;
		s/\x98/&amp;tilde;/sg;
		s/\x99/&amp;trade;/sg;
		s/\x9A/&amp;scaron;/sg;
		s/\x9B/&amp;rsaquo;/sg;
		s/\x9C/&amp;oelig;/sg;

	} else {	# This is not executed; if it were, it would convert
			# broken MS encoding to plaintext equiv (this is how
			# demoronise.pl handled it).
	
		s/\x82/,/g;
		s-\x83-<em>f</em>-g;
		s/\x84/,,/g;
		s/\x85/.../g;

		s/\x88/^/g;
		s-\x89- °/°°-g;

		s/\x8B/</g;
		s/\x8C/Oe/g;

		s/\x91/`/g;
		s/\x92/'/g;
		s/\x93/"/g;
		s/\x94/"/g;
		s/\x95/*/g;
		s/\x96/-/g;
		s/\x97/--/g;
		s-\x98-<sup>~</sup>-g;
		s-\x99-<sup>TM</sup>-g;

		s/\x9B/>/g;
		s/\x9C/oe/g;
	}

	#   Supply missing semicolon at end of numeric entity if
	#   Billy's bozos left it out.

	s/(&#[0-2]\d\d)\s/$1; /g;

	#   Fix dimbulb obscure numeric rendering of &lt; &gt; &amp;

	s/&#038;/&amp;/g;
	s/&#060;/&lt;/g;
	s/&#062;/&gt;/g;

	return $_;
}

sub old_demoronise {
	my $s = shift;
	
	# This has been adapted from a public domain script called
	# demoronizer.pl by John Walker (can be found at
	# http://www.fourmilab.ch/webtools/demoroniser/ ). That script
	# replaced MS "smart quotes" and other nonstandard characters
	# with their plaintext equivalents.
	#
	# I've modified them to convert, instead, to their UTF-8
	# equivalents.

	# (Christ this is some line noise...)

	$s =~ s/\xC2\x82/\xE2\x80\x98/sg;	# &sbquo;
	$s =~ s/\xC2\x83/\xC6\x92/sg;		# &fnof;
	$s =~ s/\xC2\x84/\xE2\x80\x9E/sg;	# &bdquo;
	$s =~ s/\xC2\x85/\xE2\x80\xA6/sg;	# &hellip;
	$s =~ s/\xC2\x86/\xE2\x80\xA0/sg;	# &dagger;
	$s =~ s/\xC2\x87/\xE2\x80\xA1/sg;	# &Dagger;
	$s =~ s/\xC2\x88/\xCB\x86/sg;		# &circ;
	$s =~ s/\xC2\x89/\xE2\x80\xB0/sg;	# &permil;
	$s =~ s/\xC2\x8A/\xC5\xA0/sg;		# &Scaron;
	$s =~ s/\xC2\x8B/\xE2\x80\xB9/sg;	# &lsaquo;
	$s =~ s/\xC2\x8C/\xC5\x92/sg;		# &OElig;
	$s =~ s/\xC2\x91/\xE2\x80\x98/sg;	# &lsquo;
	$s =~ s/\xC2\x92/\xE2\x80\x99/sg;	# &rsquo;
	$s =~ s/\xC2\x93/\xE2\x80\x9C/sg;	# &ldquo;
	$s =~ s/\xC2\x94/\xE2\x80\x9D/sg;	# &rdquo;
	$s =~ s/\xC2\x95/\xE2\x80\xA2/sg;	# &bull;
	$s =~ s/\xC2\x96/\xE2\x80\x93/sg;	# &ndash;
	$s =~ s/\xC2\x97/\xE2\x80\x94/sg;	# &mdash;
	$s =~ s/\xC2\x98/\xDC\xB2/sg;		# &tilde;
	$s =~ s/\xC2\x99/\xE2\x84\xA2/sg;	# &trade;
	$s =~ s/\xC2\x9A/\xC5\xA1/sg;		# &scaron;
	$s =~ s/\xC2\x9B/\xE2\x80\xBA/sg;	# &rsaquo;
	$s =~ s/\xC2\x9C/\xC5\x93/sg;		# &oelig;
	
	return $s;
}

# Usage: process_request_raw METHOD, URL, COOKIE, AGENTSTR [, ATTR_PAIRS ... ]
# 	METHOD is one of 'GET', 'POST', 'HEAD', etc.
# 	URL is the base url of the request (the part before the '?')
# 	COOKIE is an attribute=value pair to be used as a cookie
# 	AGENTSTR is the agent string to be used for the request
# 	ATTR_PAIRS is a set of list of attribute=value pairs to be
# 	           used to fetch the url.
# Returns: a LWP::UserAgent response object

sub process_request_raw {
	if( @_ < 3 ) { 
		croak "Usage: process_request_raw" .
		      "METHOD, URL, COOKIE, AGENTSTR [, ATTR_PAIRS ]";
	}
	
	require LWP::UserAgent;
	require HTTP::Request::Common;
	import  HTTP::Request::Common 'POST';
	require HTTP::Cookies;

	my $req		= shift;
	my $url		= shift;
	my $cookie	= shift;
	my $agentstr	= shift;
	my %pairs = @_;

	warn "E2::Interface::process_request_raw\n"	if $DEBUG > 1;

	# Put together an agentstring and cookie, and create an
	# LWP::UserAgent object to hold them

	my $str = client_name . '/' . version . " ($OS_STRING)";
	$str = "$agentstr $str" if $agentstr;
	
#	warn "\$req = $req\n\$url = $url\n\$cookie = $cookie\n" .
#		"\$agentstr = $agentstr\nAttribute pairs:" . Dumper( \%pairs )
#			if $DEBUG > 2;

	my $agent = LWP::UserAgent->new(
		agent		=> $str,
		cookie_jar	=> HTTP::Cookies->new
	);
	
	if( $cookie ) {
		$url =~ m-//(.*?)/-;	# extract domain
		
		$agent->cookie_jar->set_cookie( 
			0,
			'userpass',
			$cookie,
			'/',
			$1,
			undef,
			1,
			0,
			9999999
		);
	}


	# Execute the request

	my $request;

	if( $req eq "POST" ) {

		$request = POST( $url => [ %pairs ] );

	} else {
	
		my $s = "$url?";
		my $prepend = "";

		foreach( keys %pairs ) {
			$s .= $prepend . uri_escape( $_ ) . "=" .
				uri_escape( $pairs{$_} );
			if( !$prepend ) { $prepend = '&'; }
		}
	
		$request = HTTP::Request->new( $req => $s );
	}

	my $response = $agent->simple_request( $request );
	if( !$response->is_success ) { 
		croak "Unable to process request";
	}
	return $response;
}

1;
__END__

=head1 NAME

E2::Interface - A client interface to the everything2.com collaborative database

=head1 SYNOPSIS

	use E2::Interface;
	use E2::Message;

	# Login

	my $e2 = new E2::Interface;
	$e2->login( "username", "password" );

	# Print client information

	print "Info about " . $e2->client_name . "/" . $e2->version . ":";
	print "\n  domain:     " . $e2->domain";
	print "\n  cookie:     " . $e2->cookie";
	print "\n  parse links:" . ($e2->parse_links ? "yes" : "no");
	print "\n  username:   " . $e2->this_username;
	print "\n  user_id:    " . $e2->this_userid;

	# Load a page from e2	

	my $page = $e2->process_request( 
		node_id => 124,
		displaytype => "xmltrue"
	);

	# Now send a chatterbox message using the current
	# settings of $e2

	my $msg = new E2::Message;
	$msg->clone( $e2 );

	$msg->send( "This is a message" ); # See E2::Message

	# Logout

	$e2->logout;

=head1 DESCRIPTION

=head2 Introduction

This module is the base class for e2interface, a set of modules that interface with everything2.com. It maintains an agent that connects to E2 via HTTP and that holds a persistent state (a cookie) that can be C<clone>d to allow multiple descendants of C<E2::Interface> to act a single, consistent client. It also contains a few convenience methods.

=head2 e2interface

The modules that compose e2interface are listed below and indented to show their inheritance structure.

	E2::Interface - The base module

		E2::Node	- Loads regular (non-ticker) nodes

			E2::E2Node	- Loads and manipulates e2nodes
			E2::Writeup	- Loads and manipulates writeups
			E2::User	- Loads user information
			E2::Superdoc	- Loads superdocs
			E2::Room	- Loads room information
			E2::Usergroup	- Loads usergroup information

		E2::Ticker	- Modules for loading ticker nodes

			E2::Message	- Loads, stores, and posts msgs
			E2::Search	- Title-based searches
			E2::Usersearch	- Search for writeups by user
			E2::Session	- Session information
			E2::ClientVersion - Client version information
			E2::Scratchpad  - Load and update scratchpads

See the manpages of each module for information on how to use that particular module.

=head2 Error handling

e2interface uses Perl's exception-handling system, C<Carp::croak> and C<eval>. An example:

	my $e2 = new E2::Interface;

	print "Enter username:";
	my $name = <>; chomp $name;
	print "Enter password:";
	my $pass = <>; chomp $pass;

	eval {
		if( $e2->login( $name, $pass ) ) {
			print "$name successfully logged in.";
		} else {
			print "Unable to login.";
		}
	};
	if( $@ ) {
		if $@ =~ /Unable to process request/ {
			print "Network exception: $@\n";
		} else {
			print "Unknown exception: $@\n";
		}
	}

In this case, C<login> may generate an "Unable to process request" exception if it's unable to communicate with or receives a server error from everything2.com. This exception may be raised by any method in any package in e2interface that attempts to communicate with the everything2.com server.

Common exceptions include the following (those ending in ':' contain more specific data after that ':'):

	'Unable to process request' - HTTP communication error.
	'Invalid document'          - Invalid document received.
	'Parse error:'              - Exception raised while parsing
	                              document (the error output of
	                              XML::Twig::parse is placed after
	                              the ':'
	'Usage:'                    - Usage error (method called with
                                      improper parameters)

I'd suggest not trying to catch 'Usage:' exceptions: they can be raised by any method in e2interface and if they are triggered it is almost certainly due to a bug in the calling code.

All methods list which exceptions (besides 'Usage:') that they may potentially throw.

=head2 Threading

Network access is slow. Methods that rely upon network access may hold control of your program for a number of seconds, perhaps even minutes. In an interactive program, this sort of wait may be unacceptable.

e2interface supports a limited form of multithreading (in versions of perl that support ithreads--i.e. 5.8.0 and later) that allows network-dependant members to be called in the background and their return values to be retrieved later on. This is enabled by calling C<use_threads> on an instance of any class derived from E2::Interface (threading is C<clone>d, so C<use_threads> affects all instances of e2interface classes that have been C<clone>d from one-another). After enabling threading, any method that relies on network access will return (-1, job_id) and be executed in the background.

This job_id can then be passed to C<finish> to retrieve the return value of the method. If, in the call to C<finish>, the method has not yet completed, it returns (-1, job_id). If the method has completed, C<finish> returns a list consisting of the job_id followed by the return value of the method.

A code reference can be also be attached to a background method. See C<thread_then>.

A simple example of threading in e2interface:

	use E2::Message;

	my $catbox = new E2::Message;

	$catbox->use_threads;	# Turn on threading

	my @r = $catbox->list_public; # This will run in the background

	while( $r[0] eq "-1" ) { # While method deferred (use a string
				 # comparison--if $r[0] happens to be
				 # a string, you'll get a warning when
				 # using a numeric comparison)
		
		# Do stuff here........

		@r = $catbox->finish( $r[1] ); # $r[1] == job_id
	}

	# Once we're here, @r contains: ( job_id, return value )

	shift @r;			# Discard the job_id

	foreach( @r ) {	
		print $_->{text};	# Print out each message
	}

Or, the same thing could be done using C<thread_then>:

	use E2::Message;

	my $catbox = new E2::Message;

	$catbox->use_threads;

	# Execute $catbox->list_public in the background

	$catbox->thread_then( [\&E2::Message::list_public, $self],

		# This subroutine will be called when list_public
		# finishes, and will be passed its return value in @_

		sub {
			foreach( @_ ) {
				print $_->{text};
			}

			# If we were to return something here, it could
			# be retrieved in the call to finish() below.
		}
	);

	# Do stuff here.....

	# Discard the return value of the deferred method (this will be
	# the point where the above anonymous subroutine actually
	# gets executed, during a call to finish())

	while( $node->finish ) {} # Finish will not return a false
				  # value until all deferred methods
				  # have completed 

=head1 CONSTRUCTOR

=over

=item new

C<new> creates an C<E2::Interface> object. It defaults to using 'Guest User' until either C<login> or C<cookie> is used to log in a user.

=back

=head1 METHODS

=over

=item $e2-E<gt>login USERNAME, PASSWORD

This method attempts to login to Everything2.com with the specified USERNAME and PASSWORD.

This method returns true on success and C<undef> on failure.

Exceptions: 'Unable to process request', 'Invalid document'

=item $e2-E<gt>verify_login

This method can be called after setting C<cookie> to verify the login.

It (1) verifies that the everything2 server accepted the cookie as valid, and (2) determines the user_id of the logged-in user, which would otherwise be unavailable.

=item $e2-E<gt>logout

C<logout> attempts to log the user out of Everything2.com.

Returns true on success and C<undef> on failure.

=item $e2-E<gt>process_request HASH

C<process_request> requests the specified page via HTTP and returns its text.

It assembles a URL based upon the key/value pairs in HASH (example: C<process_request( node_id =E<gt> 124 )> would translate to "http://everything2.com/?node_id=124" (well, technically, a POST is used rather than a GET, but you get the idea)).

The returned text is stripped of HTTP headers and smart quotes and other MS weirdness prior te the return.

For those pages that may be retrieved with or without link parsing (conversion of "[link]" to a markup tag), this method uses this object's C<parse_links> setting.

All necessary character escaping is handled by C<process_request>.

Exceptions: 'Unable to process request'

=item $e2-E<gt>clone OBJECT

C<clone> copies various members from the C<E2::Interface>-derived object OBJECT to this object so that both objects will use the same agent to process requests to Everything2.com.

This is useful if, for example, one wants to use both an L<E2::Node|E2::Node> and an L<E2::Message|E2::Message> object to communicate with Everything2.com as the same user. This would work as follows:

	$msg = new E2::Message;
	$msg->login( $username, $password );

	$node = new E2::Node;
	$node->clone( $msg )

C<clone> copies the cookie, domain, parse_links value, and agentstring, and it does so in such a way that if any of the clones (or the original) change any of these values, the changes will be propogated to all the others. It also clones background threads, so these threads are shared among cloned objects.

C<clone> returns C<$self> if successful, otherwise returns C<undef>.

=item E2::Interface::debug [ LEVEL ]

C<debug> sets the debug level of e2interface.

The default debug level is zero. This value is shared by all instances of e2interface classes.

Debug levels (each displays all messages from levels lower than it):

	0 : No debug information displayed
	1 : E2::Interface info displayed once; vital debug messages
	    displayed (example: trying to perform an operation that
	    requires being logged in will cause a debug message if
	    you're not logged in)
	2 : Each non-trivial subroutine displays its name when called
	3 : Important data structures are displayed as processed

Debug messages are output on STDERR.

=item E2::Interface::client_name

C<client_name> return the name of this client, "e2interface-perl".

=item E2::Interface::version

C<version> returns the version number of this client.

=item $e2-E<gt>this_username

C<this_username> returns the username currently being used by this agent.

=item $e2-E<gt>this_user_id

C<this_user_id> returns the user_id of the current user.

This is only available after C<login> or C<verify_login> has been called (in this instance or another C<clone>d instance).

=item $e2-E<gt>domain [ DOMAIN ]

This method returns, and (if DOMAIN is specified) sets the domain used to fetch pages from e2.

By default, this is "everything2.com".

DOMAIN should contain neither an "http://" or a trailing "/".

=item $e2-E<gt>cookie [ COOKIE ]

C<cookie> returns the current everything2.com cookie (used to maintain login).

If COOKIE is specified, C<cookie> sets everything2.com's cookie to "COOKIE" and returns that value.

"COOKIE" is a string value of the "userpass" cookie at everything2.com. Example: an account with the username "willie" and password "S3KRet" would have a cookie of "willie%257CwirQfxAfmq8I6". This is generated by the everything2 servers.

This is how C<cookie> would normally be used:

	# Store the cookie so we can save it to a file

	if( $e2->login( $user, $pass ) ) {
		$cookies{$user} = $e2->cookie;
	}

	...

	print CONFIG_FILE "[cookies]\n";
	foreach( keys %cookies ) {
		print CONFIG_FILE "$_ = $cookies{$_}\n";
	}

Or:

	# Load the appropriate cookie

	while( $_ = <CONFIG_FILE> ) {
		chomp;
		if( /^$username = (.*)$/ ) {
			$e2->cookie( $1 );
			last;
		}
	}

If COOKIE is not valid, this function returns C<undef> and the login cookie remains unchanged.

=item $e2-E<gt>agentstring [ AGENTSTRING ]

C<agentstring> returns and optionally sets the value prependend to e2interface's agentstring, which is then used in HTTP requests.

=item $e2-E<gt>document

C<document> returns the text of the last document retrieved by this instance in a call to C<process_request>.

Note: if threading is turned on, this is updated by a call to C<finish>, and will refer to the document from the most recent method C<finish>ed.

=item $e2-E<gt>logged_in

C<logged_in> returns a boolean value, true if the user is logged in and C<undef> if not.

Exceptions: 'Unable to process request', 'Parse error:'

=item $e2-E<gt>use_threads [ NUMBER ]

C<use_threads> creates a background thread (or NUMBER background threads) to be used to execute network-dependant methods.

This method can only be called once for any instance (or set of C<clone>d instances), and must be disabled again (by a call to C<join_threads> or C<detach_threads>) before it can be re-enabled (this would be useful if you wanted to change the NUMBER of threads).

C<use_threads> returns true on success and C<undef> on failure.

=item $e2-E<gt>join_threads

=item $e2-E<gt>detach_threads

These methods disable e2interface's threading for an instance or a set of C<clone>d instances.

C<join_threads> waits for the background threads to run through the remainder of their queues before destroying them. C<detach_threads> detaches the threads immediately, discarding any incomplete jobs on the queue.

Both methods process any finished jobs that have not yet been C<finish>ed and return a list of these jobs. i.e.:

	my @r; my @i;
	while( @i = $e2->finish ) { push @r, \@i if $i[0] ne "-1" }
	return @r;

=item $e2-E<gt>finish [ JOB_ID ]

C<finish> handles all post-processing of deferred methods, and returns the final return value of the deferred method.

(See C<thread_then> for information on adding post-processing to a method.)

If JOB_ID is specified, it attempts to return the return value of that job, otherwise it attempts to return the return value of the first completed job on its queue.

It returns a list consisting of the job_id of the deferred method followed by the return value of the method in list context. If JOB_ID is specified and the corresponding method is not yet completed, this method returns -1. If JOB_ID is not specified, and there are methods left on the deferred queue but none of them are completed, it returns (-1, -1). If the deferred queue is empty, it returns an empty list.

If exceptions have been raised by a deferred method, or by post-processing code, they will be raised in the call to C<finish>.

=item $e2-E<gt>thread_then METHOD, CODE [, FINAL ]

C<thread_then> executes METHOD (which is a reference to an array that consists of a method and its parameters, e.g.: [ \&E2::Node::load, $e2, $title, $type ]), and sets up CODE (a code reference) to be passed the return value of METHOD when METHOD completes.

C<thread_then> is named as a sort of mnemonic device: "thread this method, then do this..."

C<thread_then> returns (-1, job_id) if METHOD is deferred; if METHOD is not deferred, thread_then immediately passes its return value to CODE and then returns the return value of CODE. This allows code to be written that can be run as either threaded or unthreaded; indeed this is how e2interface is implemented internally.

If METHOD throws an exception (threaded exceptions are thrown during the call to C<finish>), CODE will not be executed. If CODE throws an exception, any post-processing chained after CODE will not be executed. For this reason, a third code reference, FINAL, can be specified. This code will be passed no parameters, and its return value will be discarded, but it is guaranteed to be executed after all post-processing is complete, or, in the case of an exception thrown by METHOD or CODE, to be executed before C<finish> throws that exception.

=back

=head1 SEE ALSO

L<E2::Node>,
L<E2::E2Node>,
L<E2::Writeup>,
L<E2::User>,
L<E2::Superdoc>,
L<E2::Usergroup>,
L<E2::Room>,
L<E2::Ticker>,
L<E2::Message>,
L<E2::Search>,
L<E2::UserSearch>,
L<E2::ClientVersion>,
L<E2::Session>,
L<E2::Scratchpad>,
L<http://everything2.com>,
L<http://everything2.com/?node=clientdev>

=head1 AUTHOR

Jose M. Weeks E<lt>I<jose@joseweeks.com>E<gt> (I<Simpleton> on E2)

=head1 COPYRIGHT

This software is public domain.

=cut
