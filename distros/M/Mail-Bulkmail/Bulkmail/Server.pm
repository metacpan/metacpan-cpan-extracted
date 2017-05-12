package Mail::Bulkmail::Server;

# Copyright and (c) 1999, 2000, 2001, 2002, 2003 James A Thomason III (jim@jimandkoka.com). All rights reserved.
# Mail::Bulkmail::Server is distributed under the terms of the Perl Artistic License.

=pod

=head1 NAME

Mail::Bulkmail::Server - handles server connections and communication for Mail::Bulkmail

=head1 AUTHOR

Jim Thomason, jim@jimandkoka.com

=head1 SYNOPSIS

 my $server = Mail::Bulkmail::Server->new(
 	'Smtp' => 'your.smtp.com',
 	'Port' => 25
 ) || die Mail::Bulkmail::Server->error();

 #connect to the SMTP relay
 $server->connect || die $server->error();

 #talk to the server
 my $response = $server->talk_and_respond("RSET");

=head1 DESCRIPTION

Mail::Bulkmail::Server now handles server connections. Mail::Bulkmail 1.x and 2.x had all the server functionality
built into the module itself. That was nice in terms of simplicity - one module, one connection, one server, and
so on. But it had some downsides. For one thing, it only allowed for one connection. And since I wanted to allow
multiple server connections in 3.00, that had to go. For another, it was a pain in the butt to change the server
implementation. This way, you can easily write your own server class, drop it in here, and be off to the races.

For example, the Mail::Bulkmail::DummyServer module for debugging purposes.

This is not a module that you'll really need to access directly, since it is accessed internally by Mail::Bulkmail
when it is needed. Specify the data you need in the conf file and the server_file attribute, and you won't
ever need to touch this directly.

=cut

use Mail::Bulkmail::Object;
@ISA = Mail::Bulkmail::Object;

$VERSION = '3.12';

use Socket;
use 5.6.0;
use Data::Dumper ();

use strict;
use warnings;

=pod

=head1 ATTRIBUTES

=over 11

=item Smtp

stores the Smtp relay's address.

 $server->Smtp("your.smtp.com");

can either be an IP or a named address

Smtp values should be set in your server file.

=cut

__PACKAGE__->add_attr('Smtp');

=pod

=item Port

stores the port on which you'll try to connect to the SMTP relay. Probably going to be 25, since that's the
standard SMTP port.

 $server->Port(25);

Port values should be set in either your server file, or a single default in your conf file.

=cut

__PACKAGE__->add_attr('Port');

=pod

=item Domain

When you connect to an SMTP server, you must say hello and state your domain. This is your domain that you
use to say hello.

 $server->Domain('mydomain.com');

This should be the same name of the domain of the machine that you are connecting on.

Domain should be set in your conf file.

=cut

__PACKAGE__->add_attr('Domain');

=pod

=item Tries

When you try to connect to an SMTP server via ->connect, you may have issues with creating the socket
or making the connection. Tries specifies how many times you should re-try making the socket or making
the connection before failing to connect.

Make this a small number.

 $server->Tries(5);

Tries should be set in your conf file.

=cut

__PACKAGE__->add_attr('Tries');

=pod

=item max_connection_attempts

This is similar to Tries, but this governs the number of times that you can call the ->connect method.
When you have multiple servers in Mail::Bulkmail's ->servers array, there's no point in constantly re-trying
to connect to a server that fails. it'll just slow you down. max_connection_attempts makes sure that you stop
trying to connect to invalid servers.

Make this a small number as well.

 $server->max_connection_attempts(7);

max_connection_attempts should be set in your conf file.

=cut

__PACKAGE__->add_attr('max_connection_attempts');

=pod

=item envelope_limit

It's entirely likely that with a very large list you'll have a very large number of people in the
same domain.  For instance, there are an awful lot of people that have yahoo addresses.  So, for example,
say that you have a list of 100,000 people and 20,000 of them are in the yahoo.com domain and you're sending
using the envelope.  That means that the server at yahoo.com is going to receive one message with 20,000
people in the envelope!

Now, this might be a bad thing.  We don't know if the yahoo.com mail server will actually process a message
with 20,000 envelope recipients.  It may or may not and the only way to find out is to try it.  If it does work,
then great no worries. But if it doesn't, then you're stuck.  If you stop using envelope sending, you sacrifice
its major speed gains, but if you keep using it you can't send to yahoo.com.

I<envelope_limit> fixes that.

envelope_limit is precisely what it sounds like, it allows you to specify a limit on the number of recipients
that will be specified in your envelope.  That way, with our previous example, you can specify an envelope limit of
1000, for example.

 $bulk->envelope_limit(1000);

This means that yahoo.com will get 20 messages, each with 1000 recipients in the envelope.  Of course, this still
may not be small enough, so you can tweak it as much as necessary.

Setting an envelope limit does trade off some of the gains from using the envelope, but it's still over all
a vast speed boost over not using it.

envelope_limit should be set in your conf file. I recommend setting it to 100, but tweak it as necessary. Higher values
allow you to send more information and do it faster, but you're more likely to run into server's that refuse that many
recipients. Lower values are more compatible, but slightly slower.

Set envelope_limit to 0 for an infinite limit. You should never have to set it below 100 (unless you're using an infinite limit),
since RFC 2822 says that SMTP servers should always accept at least 100 recipients in the envelope

=cut

__PACKAGE__->add_attr('envelope_limit');

=pod

=item max_messages

max_messages sets the maximum number of messages to send to a particular server. This is mainly useful if you're bulkmailing
to multiple servers. You may have a server that can take some of the load, but not much of it. Assume that your list has over
100,000 people on it, and you're using one primary SMTP relay and one smaller SMTP relay to help take some of the load off
of the main one. Your primary SMTP server can handle lots of messages, but your smaller one can only take a smaller load.
That'd a good place for max_messages.

 $aux_server->max_messages(10000);

That way, your smaller server will relay no more than 10,000 messages.

Set max_messages to 0 for an infinite number of messages to go through the server. It is recommended to set max_messages
to 0.

=cut

__PACKAGE__->add_attr('max_messages');

=pod

=item max_messages_per_robin

when you set up your bulkmail object with multiple servers, max_messages_per_robin is used to determine how many messages
are sent to a server before moving onto the next.

This is the maximum number of messages that would be sent to a server in a given iteration before moving on to the next,
but it is not necessarily the exact number of messages that will be sent. If the server has reached the maximum number of
messages allowed, or the maximum number in a given connection, it will jump to the next server before reaching
the robin limit.

Set max_messages_per_robin to 0 for an infinite number of messages allowed on a given server iteration. It is recommended
to set this to 500 if you're using multiple servers, and to 0 if you're using 1 server.

The message robin counter is reset by reset_all_counters

=cut

__PACKAGE__->add_attr('max_messages_per_robin');

=pod

=item max_messages_per_connection

This sets the maximum number of messages that would be sent to a given SMTP relay in a given connection.
When this limit is reached, the server will disconnect and return that it has reached a limit.

set max_messages_per_connection to 0 for infinite messages per connection. It is recommended to keep this at 0.

The message connection counter is reset by reset_all_counters

=cut

__PACKAGE__->add_attr('max_messages_per_connection');

=pod

=item max_messages_while_awake

Sometimes, it may be useful to pause and give your server a break. max_messages_while_awake allows this. This will
specify the number of messages to send to a server before going to sleep for a certain period of time.

 $server->max_messages_while_awake(100);

Will send 100 messages to the server and then go to sleep. for the time specified by sleep_length.

Note that reaching this limit will not cause reached_limit to return a true value, so in a multi-server environment, you'll
end up sleeping a lot.

The message-while-awake counter is reset by reset_all_counters, so it is of dubious utility when using multiple servers.

Set max_messages_while_awake to 0 to never sleep. It is recommended to have max_messages_while_awake set to 0 when using
multiple servers. Set it to a positive number when using one server.

=cut

__PACKAGE__->add_attr('max_messages_while_awake');

=pod

=item sleep_length

Specifies the time to sleep (in seconds) if the server has reached the max_messages_while_awake limit.

=cut

__PACKAGE__->add_attr('sleep_length');

=pod

=item talk_attempts

The response codes for SMTP are pretty rigorously defined, which is obviously very usefull. a 5xy error is permanently fatal.
a 4xy error is temporarily fatal. It is recommended that if a 4xy error is encountered, that the client (us) should try re-sending
the same command again. talk_attempts specifies the number of times to try resending a command after receiving a 400 level error
from the server.

 $server->talk_attempts(5);

=cut

__PACKAGE__->add_attr('talk_attempts');

=pod

=item time_out

We can *finally* time out! So if your SMTP relay doesn't respond for a set period of time, the connection will automatically
disconnect and fail with an error. Set this to something high, the value is in seconds.

 $server->time_out(3000);	# 5 minutes

=cut

__PACKAGE__->add_attr('time_out');

=pod

=item time_of_last_message

stores the time that the last message was sent through this server, in epoch seconds.

=cut

__PACKAGE__->add_attr('time_of_last_message');

=pod

=item connected

boolean attribute that says whether or not this server object is connected to an SMTP relay.

Don't set this value, only read it.

=cut

__PACKAGE__->add_attr('connected');

# _not_worthless is the internal counter used for the number of failed connections attempted on a server
# why not _connection_attempts or the like to be consistent? I just liked the way the method sounded more
# $self->connect if $self->_not_worthless;
__PACKAGE__->add_attr('_not_worthless');

# internal counter for the total number of messages sent to this server object
__PACKAGE__->add_attr('_sent_messages');

# internal counter for the total number of messages sent to this server object during this "robin"
# this value is reset by reset_message_counters or by reached_limit if the max_messages_per_robin limit is reached
__PACKAGE__->add_attr('_sent_messages_this_robin');

# internal counter for the total number of messages sent to this server object during the current envelope
# this value is reset by reset_message_counters
# this counter can be accessed externally via the method "reached_envelope_limit"
__PACKAGE__->add_attr('_sent_messages_this_envelope');

# internal counter for the total number of messages sent to this server object during this connection
# this value is reset by reset_message_counters or by reached_limit if the max_messages_per_connection limit is
# reached. Additionally, reached_limit will disconnect the server if this limit is reached
__PACKAGE__->add_attr('_sent_messages_this_connection');

# internal counter for the total number of messages sent to this server object before sleeping
# this value is reset by reset_message_counters or by reached_limit if the max_messages_while_awake limit is
# reached. Additionally, reached_limit will sleep for the amount of time specified by sleep_length, if
# sleep_length is specified
__PACKAGE__->add_attr('_sent_messages_while_awake');

=pod

=item CONVERSATION

This is an optional log file to keep track of your SMTP conversations

CONVERSATION may be either a coderef, globref, arrayref, or string literal.

If a string literal, then Mail::Bulkmail::Server will attempt to open that file (in append mode) as your log:

 $server->CONVERSATION("/path/to/my/conversation");

If a globref, it is assumed to be an open filehandle in append mode:

 open (C, ">>/path/to/my/conversation");
 $server->CONVERSATION(\*C);

if a coderef, it is assumed to be a function to call with the address as an argument:

 sub C { print "CONVERSATION : ", $_[1], "\n"};	#or whatever your code is
 $server->CONVERSATION(\&C);

if an arrayref, then the conversation will be pushed on to the end of it

 $server->CONVERSATION(\@conversation);

Use whichever item is most convenient, and Mail::Bulkmail::Server will take it from there.

B<Be warned>: This file is going to get B<huge>. Massively huge. You should only turn this on for debugging
purposes and B<never> in a production environment. It will log the first 50 characters of a message sent to the
server, and the full server response.

=cut

__PACKAGE__->add_attr(['CONVERSATION',		'_file_accessor'], '>>');

=pod

=item socket

socket contains the socket that this Server has opened to its SMTP relay. You'll probably never talk to this directly,
but it's here, just in case you want it.

=cut

__PACKAGE__->add_attr('socket');

#this is a hashref to internally store our ESMTP options received from EHLO
__PACKAGE__->add_attr('_esmtp');

=pod

=back

=head1 METHODS

=over 11

=item increment_messages_sent

This method will increment the server object's internal counters storing the total number of messages
sent, the total sent this robin, the total sent this connection, the total sent while awake, and the total
sent this envelope.

It will also store the time the last message is sent.

=cut

sub increment_messages_sent {
	my $self = shift;

	$self->_sent_messages($self->_sent_messages + 1);

	$self->_sent_messages_this_robin($self->_sent_messages_this_robin + 1);

	$self->_sent_messages_this_connection($self->_sent_messages_this_connection + 1);

	$self->_sent_messages_while_awake($self->_sent_messages_while_awake + 1);

	$self->_sent_messages_this_envelope($self->_sent_messages_this_envelope + 1);

	$self->time_of_last_message(time);

	return $self;
};

=pod

=item reset_message_counters

This message will reset the internal counters for the messages sent this robin, messages sent this connection,
and messages sent while awake back to 0.

=cut

sub reset_message_counters {
	my $self = shift;

	#$self->_sent_messages(0);					#this never gets reset

	$self->_sent_messages_this_robin(0);

	#$self->_sent_messages_this_connection(0);	#this gets set upon connect

	$self->_sent_messages_while_awake(0);

	$self->_sent_messages_this_envelope(0);

	return $self;
};

=pod

=item reset_envelope_counter

The envelope counter behaves slightly differently than the other counters, so we have a separate method to reset the internal
envelope counter.

=cut

sub reset_envelope_counter {
	my $self = shift;

	$self->_sent_messages_this_envelope(0);

	return $self;
};

=pod

=item reached_envelope_limit

This method returns 1 if we've reached the envelope limit, 0 otherwise

=cut

sub reached_envelope_limit {
	my $self = shift;

	return 1 if $self->envelope_limit && $self->_sent_messages_this_envelope >= $self->envelope_limit;
};

=pod

=item reached_limit

This method will tell you if the server has reached the max_messages, max_messages_per_connection, or max_messages_per_robin
limits. Also, if you reach the max_messages_while_awake limit, this method will cause you to sleep for the time period
specified in sleep_length

 Return values:
 1 : reached max_messages limit, server becomes worthless and will not be used again
 2 : reached max_messages_per_connection limit, server will disconnect
 3 : reached max_messages_per_robin limit

=cut

sub reached_limit {
	my $self = shift;

	#sleep if we're supposed to sleep
	if ($self->max_messages_while_awake && $self->_sent_messages_while_awake >= $self->max_messages_while_awake){
		sleep $self->sleep_length if $self->sleep_length;
		$self->_sent_messages_while_awake(0);
	};

	if ($self->max_messages && $self->_sent_messages >= $self->max_messages){
		$self->disconnect();
		$self->_sent_messages_this_connection(0);
		$self->_sent_messages_this_robin(0);
		$self->_not_worthless(0);
		return 1;
	}
	elsif ($self->max_messages_per_connection && $self->_sent_messages_this_connection >= $self->max_messages_per_connection){
		$self->disconnect();
		$self->_sent_messages_this_connection(0);
		$self->_sent_messages_this_robin(0);
		return 2;
	}
	elsif ($self->max_messages_per_robin && $self->_sent_messages_this_robin >= $self->max_messages_per_robin){
		$self->_sent_messages_this_robin(0);
		return 3;
	}
	#otherwise, we've reached no limits
	else {
		return 0;
	};
};

=pod

=item new

Standard constructor. See Mail::Bulkmail::Object for more information.

=cut

sub new {
	my $self = shift->SUPER::new(
		'_sent_messages'					=> 0,
		'_sent_messages_this_robin'			=> 0,
		'_sent_messages_this_connection'	=> 0,
		'_sent_messages_while_awake'		=> 0,
		'_sent_messages_this_envelope'		=> 0,
		'connected'							=> 0,
		'_esmtp'							=> {},
		'_not_worthless'					=> 5,	#default to 5 regardless of the conf file
		@_
	) || return undef;

	$self->_not_worthless($self->max_connection_attempts) if $self->max_connection_attempts;

	return $self;
};

=pod

=item connect

Connects this server object to the SMTP relay specified with ->Smtp and ->Port
This method will set ->connected to 1 if it successfully connects.

 $server->connect() || die "Could not connect : " . $server->error;

Upon connection, ->connect will issue a HELO command for the ->Domain specified.

This method is known to be able to return:

 MBS001 - cannot connect to worthless servers
 MBS002 - could not make socket
 MBS003 - could not connect to server
 MBS004 - no response from server
 MBS005 - server won't say HELO
 MBS010 - can't greet server w/o domain
 MBS011 - server gave an error for EHLO
 MBS015 - timed out waiting for response upon connect
 MBS016 - server didn't respond to EHLO, trying HELO (non-returning error)
 MBS017 - cannot connect to server, no Tries parameter

=cut

sub connect {

	my $self = shift;

	return $self if $self->connected();

	#if we have no Tries parameter, then the server is unquestionably worthless
	unless ($self->Tries) {
		$self->_not_worthless(0);
		return $self->error("Cannot connect to server - no Tries parameter set", "MBS017");
	};

	#if we have no Domain, then the server is unquestionably worthless
	unless ($self->Domain) {
		$self->_not_worthless(0);
		return $self->error("Cannot greet server without domain", "MBS010");
	};

	return $self->error("Cannot connect to worthless servers", "MBS001") unless $self->_not_worthless > 0;

	my $bulk = $self->gen_handle();

	my ($s_tries, $c_tries) = ($self->Tries, $self->Tries);

	1 while ($s_tries-- && ! socket($bulk, PF_INET, SOCK_STREAM, getprotobyname('tcp')));
	if ($s_tries < 0){
		$self->_not_worthless($self->_not_worthless - 1);
		return $self->error("Could not make socket for " . $self->Smtp . ", Socket error ($!)", "MBS002");
	}
	else {

		my $paddr = sockaddr_in($self->Port, inet_aton($self->Smtp));

		1 while ! connect($bulk, $paddr) && $c_tries--;

		if ($c_tries < 0){
			$self->_not_worthless($self->_not_worthless - 1);
			return $self->error("Could not connect to " . $self->Smtp . ", Connect error ($!)", "MBS003") if $c_tries < 0;
		}
		else {

			$@ = undef;
			eval {
				local $SIG{"ALRM"} = sub {die "timed out"};

				eval{ alarm($self->time_out) if $self->time_out; };	#catch it in case alarm isn't implemented (stupid windows)

				#keep our bulk pipes piping hot.
				select((select($bulk), $| = 1)[0]);

				local $\ = "\015\012";
				local $/ = "\015\012";

				my $response = <$bulk> || "";
				if (! $response || $response =~ /^[45]/) {
					$self->_not_worthless($self->_not_worthless - 1);
					return $self->error("No response from server: $response", "MBS004");
				};

				#grab our domain
				my $domain = $self->Domain;

				#first, we'll try to say EHLO
				print $bulk "EHLO $domain";

				$response = <$bulk> || "";

				#log our conversation, if desired.
				if ($self->CONVERSATION){
					$self->logToFile($self->CONVERSATION, "Said to server: 'EHLO'");
					$self->logToFile($self->CONVERSATION, "\tServer replied: '$response'");
				};

				#now, if the server didn't respond or gave us an error, we'll fall back and try saying HELO instead
				if (! $response || $response =~ /^[45]/){

					$self->error("Server did not respond to EHLO...trying HELO", "MBS016");

					print $bulk "HELO $domain";

					$response = <$bulk> || "";

					#log our conversation, if desired
					if ($self->CONVERSATION){
						$self->logToFile($self->CONVERSATION, "Said to server: 'HELO'");
						$self->logToFile($self->CONVERSATION, "\tServer replied: '$response'");
					};

					if (! $response || $response =~ /^[45]/) {
						$self->_not_worthless($self->_not_worthless - 1);
						return $self->error("Server won't say HELO: $response", "MBS005");
					};
				}
				#otherwise, it accepted our EHLO, so we'll read in our list of ESMTP options
				else {
					my $receiving = 1;

					while ($receiving) {
						my $r = <$bulk> || "";

						#log our conversation, if desired
						if ($self->CONVERSATION){
							$self->logToFile($self->CONVERSATION, "\tServer replied: '$r'");
						};

						$self->error("Server gave an error for EHLO : $r", "MBS011") if ! $r || $r =~ /^[45]/;

						#extract out and store our ESMTP options for possible later use
						$r =~ /^\d\d\d[ -](\w+)/;
						my $esmtp_option = $1;
						$self->_esmtp->{$esmtp_option} = 1 if $esmtp_option;

						#multi-line replies are of the form \d\d\d-, single line (or last line replies are \d\d\d" "
						$receiving = 0 if $r =~ /^\d\d\d /;
					};

				};	#end successful EHLO

				#clear our alarm
				eval { alarm(0); }; #catch it in case alarm isn't implemented (stupid windows)

			}; #end eval wrapping up our time out


			if ($@){
				$self->_not_worthless($self->_not_worthless - 1);
				return $self->error("Timed out waiting for response on connect", "MBS015");
			};

			$self->socket($bulk);

			$self->connected(1);
			$self->_sent_messages_this_connection(0);

			return $self;
		};
	};
};

=pod

=item disconnect

disconnects the server object from the SMTP relay. Before disconnect, it will issue a "RSET" and then a "quit" command
to the SMTP server, then close the socket. disconnect sets ->connected to 0.

disconnect can also disconnect quietly, i.e., it won't try to issue a RSET and then quit before closing the socket.

 $server->disconnect(); 			#issues RSET and quit
 $server->disconnect('quietly');	#issues nothing

=cut

sub disconnect {

	my $self	= shift;
	my $quietly	= shift;

	return $self unless $self->connected();

	$self->talk_and_respond('RSET') unless $quietly;	#just to be polite
	$self->talk_and_respond('quit') unless $quietly;

	if (my $socket = $self->socket) {
		close $socket;
		$socket = undef;
	};

	$self->socket(undef);

	#wipe out our ESMTP hash, since it may not be valid upon next connect
	$self->_esmtp({});

	$self->connected(0);

	return $self;

};

=pod

=item talk_and_respond

talk_and_respond takes one argument and sends it to your SMTP relay. It then listens for a response.

 my $response = $server->talk_and_respond("RSET");

If you're not connected to the relay, talk_and_respond will attempt to connect.

This method is known to be able to return:

 MBS006 - cannot talk w/o speech
 MBS007 - cannot talk to server
 MBS008 - server won't respond to speech
 MBS009 - server disconnected
 MBS012 - temporarily won't respond to speech...re-trying
 MBS013 - could never resolve temporary error
 MBS014 - timed out waiting for response
 MBS018 - No file descriptor

=cut

sub talk_and_respond {
	my $self	= shift;

	my $talk	= shift || return $self->error("Cannot talk w/o speech", "MBS006");

	my $attempts= shift || $self->talk_attempts;

	unless ($self->connected){
		$self->connect || return undef;
	};

	my $bulk = $self->socket();

	local $\ = "\015\012";
	local $/ = "\015\012";

	unless (fileno($bulk)) {
		$self->disconnect('quietly');
		return $self->error("No file descriptor...socket appears to be closed. Disconnecting to be safe", "MBS018");
	};

	unless (print $bulk $talk){
		return $self->error("Cannot talk to server : $!", "MBS007");
	};

	#keep track of the first 50 characters, w/o returns for logging purposes
	my $short_talk = substr($talk, 0, 50);
	$short_talk .= "...(truncated)" if length $talk > length $short_talk;

	if ($self->CONVERSATION){
		$self->logToFile($self->CONVERSATION, "Said to server: '$short_talk'");
	};

	my $response = undef;

	#this is true as long as we're expecting more responses from the server
	my $receiving = 1;

	$@ = undef;
	eval {

		local $SIG{"ALRM"} = sub {die "timed out"};

		eval { alarm($self->time_out) if $self->time_out; }; #catch it in case alarm isn't implemented (stupid windows)

		while ($receiving) {

			my $r = <$bulk> || "";

			if ($self->CONVERSATION){
				$self->logToFile($self->CONVERSATION, "\tServer replied: '$r'");
			};

			#500 codes are permanent fatal errors
			if (! $r || $r =~ /^5/){

				return $self->error("Server won't respond to '$talk' : $r" . $self->Smtp, "MBS008");
			}

			#400 error codes are temporary fatal errors
			#If we get a 4xy error, we're going to retry this same command up to our
			#talk_attempts parameter. If it never works, we'll fail completely
			elsif ($r && $r =~ /^4/){
				my $next_attempts = $attempts - 1;
				if ($next_attempts > 0) {
					$self->error("Temporary response to $talk : $r...retrying", "MBS012");
					return $self->talk_and_respond($talk, $next_attempts);
				}
				else {
					return $self->error("Server won't respond to $talk, and re-attempts for temporary code exhausted", "MBS013");
				};
			}

			#otherwise, if we got a 221, we were disconnected.
			elsif ($r && $r =~ /^221/){
				#if we disconnected from something other than a quit, then log the error
				if ($talk ne 'quit'){
					$self->disconnect();
					return $self->error("Server disconnected in response to '$talk': $r", "MBS009");
				}
				#otherwise, we're happy, so we'll return a true value
				else {
					return 'disconnected';
				};
			}

			#finally, if it's something else, then we're gonna assume it's a happy response
			#and tack it on to the response we return
			else {
				# Responses of \d\d\d" " indicate we're done and there's nothing
				# else coming
				$receiving = 0 if $r =~ /^\d\d\d / || $r =~ /^\d\d\d$/;

				$response .= $r;
			};

		};	#end while

		#clear our alarm
		eval { alarm(0); }; #catch it in case alarm isn't implemented (stupid windows)

	};	#end eval

	if ($@){
		$self->disconnect('quietly');
		return $self->error("Timed out waiting for response to $talk", "MBS014");
	};

	return $response;
};

#make sure that we're disconnected
sub DESTROY {
	my $self = shift;
	$self->disconnect if $self->connected;
	$self = undef;
};

=pod

=item create_all_servers

create_all_servers will iterate through the file specified in server_file in the conf file and return an arrayref of all
server objects created.

 define package Mail::Bulkmail::Server

 server_file	= ./server_file.txt

your server file should be of the format of another Mail::Bulkmail conf file, containing definitions
for all of the SMTP servers you want to use. See the examples below for how to set up the conf files.

If you would like to specify a different conf file, pass that as an argument.

 my $servers = Mail::Bulkmail::Server->create_all_servers('/path/to/new/server_file.txt');

This will then ignore the server_file in the conf file and use the one passed.

You may also pass hashrefs of init data for new servers.

 my $servers = Mail::Bulkmail::Server->create_all_servers(
 	{
 		'Smtp' => 'smtp.yourdomain.com'
 	},
 	{
 		'Smtp' => 'smtp2.yourdomain.com'
 	},
 	{
 		'Smtp' => 'smtp3.yourdomain.com'
 	}
 ) || die Mail::Bulkmail::Server->error;

This is called internally by Mail::Bulkmail's constructor, so you probably won't ever need to touch it.

=cut

sub create_all_servers {
	my $self	= shift;

	my $class	= ref $self || $self;

	my $master_conf = $self->read_conf_file();

	my $conf = {};

	if ($_[0] && ! ref $_[0]){
		my $file = shift;
		$conf = $self->read_conf_file($file);
	}
	else {
		foreach my $pkg (@{$class->isa_path() || []}){
			if ($master_conf->{$pkg}->{"server_file"}){
				$conf = $self->read_conf_file($master_conf->{$pkg}->{"server_file"});
			};
		};
	};

	my $data = {'Smtp' => []};

	my @settables = qw(Smtp Port Tries Domain max_messages max_messages_per_robin max_messages_per_connection
								max_messages_while_awake sleep_length max_connection_attempts envelope_limit
								talk_attempts time_out CONVERSATION);

	foreach my $attribute (@settables) {

		foreach my $pkg (@{$class->isa_path() || []}){
			foreach my $method (keys %{$conf->{$pkg}}){
				$conf->{$class}->{$attribute} ||= $conf->{$pkg}->{$attribute};
			};
		};

		next unless defined $conf->{$class}->{$attribute};

		@{$data->{$attribute}} = ref $conf->{$class}->{$attribute}
			? @{$conf->{$class}->{$attribute}}
			: ($conf->{$class}->{$attribute});

	};

	my @servers = ();

	while (@{$data->{"Smtp"}}){
		my %init = ();

		foreach my $attribute (@settables) {
			$init{$attribute} = shift @{$data->{$attribute}} if $data->{$attribute} && @{$data->{$attribute}};
		};

		my $server = $class->new(
			%init
		) || return undef;

		push @servers, $server;
	};

	if (@_){
		while (my $init = shift){
			my $server = $class->new(
				%$init
			) || return undef;

			push @servers, $server;
		};
	};

	return \@servers;

};

1;

__END__

=pod

=back

=head1 SAMPLE SERVER FILE

It is recommended that you define your server entries in your server file. See Mail::Bulkmail::Object and Mail::Bulkmail
for more information on conf file set up and how to define your server_file.

 #in your conf file, you want this
 define package Mail::Bulkmail::Server

 #your server file
 server_file = /etc/mb/server.file.txt

Now, your server file should look like this:

 define package Mail::Bulkmail::Server

 #set up the first server
 Smtp @= smtp1.yourdomain.com
 Port @= 25
 Tries @= 5
 max_messages_per_robin @= 1000
 envelope_limit @= 100

 #set up the second server
 Smtp @= smtp2.yourdomain.com
 Port @= 25
 Tries @= 5
 max_messages_per_robin @= 1000
 envelope_limit @= 100

 #set up the third server
 Smtp @= smtp3.yourdomain.com
 Port @= 25
 Tries @= 5
 max_messages_per_robin @= 1000
 envelope_limit @= 100

Alternatively, you can use defaults in your master conf file.

 #your server file
 server_file = /etc/mb/server.file.txt

 #These values will apply to all servers
 Port = 25
 Tries = 5
 max_message_per_robin = 1000
 envelope_limit = 100

Now, your server file should look like this:

 define package Mail::Bulkmail::Server

 #set up the first server
 Smtp @= smtp1.yourdomain.com

 #set up the second server
 Smtp @= smtp2.yourdomain.com

 #set up the third server
 Smtp @= smtp3.yourdomain.com

Be warned that if you want to set up a value for one server, you should set it up for all of them. Either
specify the attribute for a server in the master conf file, or specify it multiple times for all servers.


=head1 SEE ALSO

Mail::Bulkmail, Mail::Bulkmail::DummyServer

=head1 COPYRIGHT (again)

Copyright and (c) 1999, 2000, 2001, 2002, 2003 James A Thomason III (jim@jimandkoka.com). All rights reserved.
Mail::Bulkmail::Server is distributed under the terms of the Perl Artistic License.

=head1 CONTACT INFO

So you don't have to scroll all the way back to the top, I'm Jim Thomason (jim@jimandkoka.com) and feedback is appreciated.
Bug reports/suggestions/questions/etc.  Hell, drop me a line to let me know that you're using the module and that it's
made your life easier.  :-)

=cut
