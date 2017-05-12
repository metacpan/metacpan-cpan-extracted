package IO::NonBlocking;

use strict;
use warnings;
use POSIX;
use IO::Socket;
use IO::Select;
use Socket;
use Fcntl;
use Tie::RefHash;
use vars qw($VERSION);

$VERSION = '1.035';

my @now=localtime(time);
my $cronCounter=$now[0]+60*$now[1]+3600*$now[2]+3600*24*$now[3];
my %buff;

# begin with empty buffers
my %inbuffer  = ();
my %outbuffer = ();
my %ready = ();

my %turn_timeout;
my %turn_timeout_trigger;
my $select;
my %idle;
my %timer;

tie %ready, 'Tie::RefHash';

my $daily=0;

sub new{
	my($proto,@arg)=@_;
	my $class=ref($proto) || $proto;
	my %hash=%{$arg[0]};

	my $self={};

	$self->{serverName}=$hash{'server_name'} || die("server_name is required");
	$self->{port}=$hash{'port'} || die("port is required");
	$self->{delimiter}=defined($hash{delimiter}) ? $hash{delimiter} : "\0";
	$self->{string_format}=defined($hash{string_format}) ? $hash{string_format} : '.*?';
	$self->{timeout}=defined($hash{timeout}) ? $hash{timeout} : 300;
	$self->{piddir}=defined($hash{piddir}) ? $hash{piddir} : '/tmp';

	bless $self,$class;
}

sub start_turn{
	my $self=shift;
	my $client=shift;
	my $time=shift;

	$turn_timeout{$client}=$time;
	$turn_timeout_trigger{$client}=$_[0];
}

sub stop_time {
	my $self=shift;
	my $client=shift;

	$turn_timeout{$client}=-1;
	delete($turn_timeout_trigger{$client});
}

sub close_client {
	my $self=shift;
	my $client=shift;

	delete $turn_timeout{$client};
	delete $turn_timeout_trigger{$client};
	delete $idle{$client};
	delete $inbuffer{$client};
	delete $outbuffer{$client};
	delete $ready{$client};

	$select->remove($client);
	close $client if $client;
}

sub disconnect_client {
	my $self=shift;
	my $client=shift;

	delete $turn_timeout{$client};
	delete $turn_timeout_trigger{$client};
	delete $idle{$client};
	delete $inbuffer{$client};
	delete $outbuffer{$client};
	delete $ready{$client};

	$self->onClientDisconnected($client);

	$select->remove($client);
	close $client if $client;
}

sub start{
	my $self=shift;
	my $current_time=time;

	print "Listening on port ".$self->port."\n";

	my $server = IO::Socket::INET->new(	
					LocalPort => $self->port,
					Listen    => 50,
					Proto	=> 'tcp',
					Reuse	=> 1)
				  or die "Can't make server socket: $@\n";

	$self->nonblock($server);
	$select = IO::Select->new($server);

	open(FILE,">".$self->piddir."/".$self->serverName) or die "Cannot write PID file: $!\n";
	print FILE $$;
	close(FILE);

	$self->onServerInit;

	while (1) {
		my $client;
		my $rv;
    		my $data;

		# cron
		my $this_time=time;
		if ($current_time != $this_time) {
		  foreach $client($select->handles) {
		    next if $server == $client;

		    if ($turn_timeout{$client} != -1) {
		      if ($turn_timeout{$client} <= 0) {
			&{$turn_timeout_trigger{$client}}($self);
			delete $turn_timeout_trigger{$client};
			$turn_timeout{$client} = -1;
		      } else {
			--$turn_timeout{$client};
		      }
		    } 
		  }

		  $self->onSheddo;
		  $current_time=$this_time;
		}

		#timeout the Idles

		if($cronCounter % ($self->{timeout}+30) == 0){
			foreach $client ($select->handles) {
				next if $server == $client;

				my $this_time=time;

				if( $this_time - $idle{$client} >= $self->{timeout} ){
					$self->disconnect_client($client);
					next;
				}
			}
		}

		# check for new information on the connections we have

		# anything to read or accept?
    		foreach $client ($select->can_read(1)) {

 			if ($client == $server) {
            			# accept a new connection

				$client = $server->accept();
				$select->add($client);
				$self->nonblock($client);

				$self->onClientConnected($client);
				$idle{$client}=time;
				$turn_timeout{$client}=-1;
			} else {
            			# read data

				$data = '';
				$rv   = $client->recv($data, POSIX::BUFSIZ, 0);

				unless (defined($rv) && length $data) {
                			# This would be the end of file, so close the client
					$self->disconnect_client($client);
					next;
				}

				$inbuffer{$client} .= $data;

				# test whether the data in the buffer or the data we
				# just read means there is a complete request waiting
				# to be fulfilled.  If there is, set $ready{$client}
				# to the requests waiting to be fulfilled.
				my $dm=$self->{delimiter};
				my $sf=$self->{string_format};

				while ($inbuffer{$client} =~ s/($sf)$dm//s) {
					push( @{$ready{$client}}, $1 );
				}

				$idle{$client}=time;
			}
		}

		# Any complete requests to process?
		foreach $client (keys %ready) {
			$self->handle($client);
		}

		my @bad_client;

		# Buffers to flush?
		foreach $client ($select->can_write(1)) {
			# Skip this client if we have nothing to say
			next unless exists $outbuffer{$client};

			eval{
				$rv = $client->send($outbuffer{$client}, 0);
			};
			push(@bad_client,$client),next if $@;

			unless (defined $rv) {
            			# Whine, but move on.

				warn "I was told I could write, but I can't.\n";
				next;
			}

			if ( $rv == length $outbuffer{$client} || $! == POSIX::EWOULDBLOCK) {
				substr($outbuffer{$client}, 0, $rv) = '';
				delete $outbuffer{$client} unless length $outbuffer{$client};
			} else {
				# Couldn't write all the data, and it wasn't because
				# it would have blocked.  Shutdown and move on.

				$self->disconnect_client($client);
				next;
			}
		}

		foreach (@bad_client){
			$self->disconnect_client($client);
		}

		# Out of band data?
		foreach $client ($select->has_exception(0)) {
			# arg is timeout
        			# Deal with out-of-band data here, if you want to.
		}
	}

}

sub nonblock {
	my $self=shift;
	my $socket=shift;
	my $flags;
	
	$flags = fcntl($socket, F_GETFL, 0)
		or die "Can't get flags for socket: $!\n";
	fcntl($socket, F_SETFL, $flags | O_NONBLOCK)
		or die "Can't make socket nonblocking: $!\n";
}

sub handle {
	my $self=shift;
	my $client = shift;
	my $request;

	# requests are in $ready{$client}
	# send output to $outbuffer{$client}

	foreach $request (@{$ready{$client}}) {
        		# $request is the text of the request
        		# put text of reply into $outbuffer{$client}

		$self->onReceiveMessage($client,$request);
	}

	delete $ready{$client};
}

#============= facility functions ============

sub getip {
        my $self=shift;
	$_[0]->sockhost();
}

sub getport {
        my $self=shift;
	$_[0]->sockport();
}

sub piddir{
	my $self=shift;

	return $self->{piddir};
}

sub serverName{
	my $self=shift;

	return $self->{serverName};
}

sub port{
	my $self=shift;

	return $self->{port};
}

sub sendmsg{
        my $self=shift;
        my $client=shift;
        my $msg=shift;

        $outbuffer{$client}.=$msg.$self->{delimiter};
}

sub onServerInit {
}

sub onClientConnected{
	my $self=shift;
	my $client=shift;
}

sub onClientDisconnected{
	my $self=shift;
	my $client=shift;
}

sub onReceiveMessage{
	my $self=shift;
	my $client=shift;
	my $request=shift;
}

sub onSheddo{
	my $self=shift;

	foreach (sort {$a <=> $b} keys %timer) {
	  unless ($cronCounter % $_) {
	    &{$timer{$_}}($self);
	  }
	}

	if ($cronCounter % 4527 == 0) {
	  #Sync time

	  my @now=localtime(time);
	  $cronCounter=$now[0]+60*$now[1]+3600*$now[2]+3600*24*$now[3];
	  return;
	}

	++$cronCounter;
}

sub cron {
        my $self=shift;

	$timer{$_[0]}=$_[1];
}

sub add_socket {
	my $self=shift;
	my $sock=shift;

	$select->add($sock);
	$self->nonblock($sock);

	$idle{$sock}=time;
	$turn_timeout{$sock}=-1;	
}

sub select {
	my $self=shift;

	$select;
}

1;
__END__

=head1 NAME

IO::NonBlocking - Object-oriented interface to non-blocking IO server implementation.

=head1 SYNOPSIS

	package FooServer;
	use IO::NonBlocking;
	use strict;
	use vars qw (@ISA);
	@ISA=qw(IO::NonBlocking);

	sub new {
		my $class=ref($_[0]) || $_[0];
		my $self=IO::NonBlocking->new(
				{
					server_name => 'FooServer',
					port => 52721,
					timeout => 300,
					piddir => '/tmp'
				}
			);

		bless $self,$class;
	}

	sub onClientConnected {
		my $self=shift;
		my $client=shift;
	
		print $self->getip($client),":",$self->getport($client),"\n";
	}

	sub onClientDisconnected {
		my $self=shift;
		my $client=shift;
	
		print "Disconnected\n";
	}

	1;

	package main;
	my $obj=FooServer->new;
	$obj->start;

=head1 DESCRIPTION

IO::NonBlocking is a non-blocking IO server style, runable on non-blocking IO capable OS -- most Unix and it's cloned platforms.

The non-blocking server engine is built, basing on a page of codes of the Tom Christiansen's Perl Classic Cook Book.

If you have some experiences with IO::Multiplex, you'll see that the module has poor efficiency.
Since IO-multiplexing blocks all clients when one sends his data slowly. At first, I did appreciate the module much, 
but when user increases, everything is slowed down. 

After that, I had tried many fruitless improvement to the module and 
they didn't work at all. I'd realized that there weren't exist such a non-blocking server module on CPAN, after mining for many nights. 

At last, I did copy my core code from the CookBook 
and it worked like charm at my first glance, nevertheless the code has some bugs 
that make my server crash, however, I've fixed it and added many useful features to decide to release it as a module to CPAN.

=head2 Features

=item Inheritance only

the purpose of this module is for inheritance only, it cannot do such a static call, but you can override some callback functions to make it work.

=item Timer

enable your server to execute sub routines at some configurable times

=item Timeout

Imagine a client is disconnected by his ISP, by all means of TCP/IP , there's no way a server can notice about the disconnection in acceptable time.Timeout feature comes to handle this situation. You can set your server to autometically disconnect any clients who idle for XXX seconds

=item Turn Timeout

If you plan to create a multi-player turn based game, maybe you need a time counter on server. Since time counter on client side is not secure. Probably a client can send his a fake timeout message to fool your server, if you do not manage this thing on server side.

=head2 Usage

To implement a server service from this module, you have to inherit from it, something like this:

	package FooServer;
	use IO::NonBlocking;
	@ISA=qw(IO::NonBlocking);

	1;

	package main;

	$obj=FooServer->new(
        	{
                	'server_name' => 'FooServer',
                	'port' => 52721
        	});

	$obj->start;

and then, you can implement some methods to your modules to handle events which are:

        sub onServerInit {		# this method is called after socket initialization
					# but before it goes to the listening mode
					# to provide additional server initialization
        }

	sub onClientConnected{		# triggered when a client connect to server
		my $self=shift;
        	my $client=shift;

	}

	sub onClientDisconnected{	# triggered when 
	                                # a client disconnect itself from yourserver
        	my $self=shift;		# or the client is timeout
	        my $client=shift;

	}

	sub onReceiveMessage{		# triggered when a client send a message to server
        	my $self=shift;
        	my $client=shift;
        	my $request=shift;

	}

The variable $client in every function above is socket handle of each client. You can write some data to it via print funcation as:

	print $client "life is only temporary"; 

but this isn't the only way you can send messages to a client. I've written message sender function, called sendmsg($client,$msg) to buffer outgoing data, to boost efficiency.
Let's see a sample code:

        package FooServer;
        use IO::NonBlocking;
        @ISA=qw(IO::NonBlocking);

        sub onClientConnected {
                my $self=shift;
                my $client=shift;

                print "Connected ".$self->getip($client).":".$self->getport($client)."\n";
        }

        sub onClientDisconnected{
                my $self=shift;
                my $client=shift;

                print "Disconnected\n";
        }

       sub onReceiveMessage{
                my $self=shift;
                my $client=shift;
                my $request=shift;

                print $client "Hello ";
                $self->sendmsg($client,"World");
        }

        1;

        package main;

        $obj=FooServer->new(
               {
                        server_name => 'FooServer',
                        port => 52721,
                        delimiter => "\n"
                });

        $obj->start;

The code should work fine on unix cloned platform.
Beside, you can pass, 'timeout' to the anonymous of constructor so that any client who is idle for a time you have configured will be autometically disconnected. By defaults 'timeout' is 300 seconds.
The following parameters are all of the constructor.

	'server_name'	for name of server, you shouldn't leave blank
	'port'		the port where you want you server to reside in
	'string_format' generally, string format is ".*?". If your message format is simple enough, do not set this parameter. In addition, when the module parses message, it executes something like this "while ($buffer =~ s/($string_format)$delimiter//) {" and throw $1 to onReceiveMessage.
	'delimiter'	the delimiter of you message of you protocol default is "\0"
	'timeout'	timeout in second as I've stated, default is 300 second
	'piddir'	where pid file is kept, default is '/tmp' 
	                (all pid file is written in piddir with file name as "server_name"

If you want to do some cron job with your server, the module provide cron($time,$refcode) for the requirement. Here is an example. ($time is in second)

	sub kkk {
		my $self=shift;

		print "Ok, Computer\n";
	}

	$obj->cron(5,\&kkk);

If you create sub kkk in FooServer namespace, the above code will look like:

	$obj->cron(5,\&FooServer::kkk);

The module pass every timer function with $self so that you can access you package variables.

Moreover, IO::NonBlocking give you turn timeout feature. You may not understand it at first, I'll explain. Imagine two client are playing online chess together, sooner or later a player of one side is disconnected for internet by his ISP. In this circumstance, the chess server will not know the disconnection, because TCP give chances to a peer that cannot reachable. This process takes a long time. If the chess protocol counts times of each turn via client, the protocol fail in this case. Nevertheless, the problem is solved by counting time on server. I've provide 2 methods for this job. They are:

	start_turn($client,$time);	start server counter for each client
	stop_time($client);		clear server counter for each client

Whenever the counter is set, it continues decreasing 1 for each second. When the counter reach 0, the sub routine that you specifies triggered. For example:

	sub kuay {
            my $self=shift;
            print $self->port,"\n";
        }

        my $toggle=0;

        sub onReceiveMessage {
            my $self=shift;
            my $client=shift;
            my $request=shift;

            print "Messeged\n";
            $toggle^=1;

            if ($toggle) {
                $self->start_turn($client,5,\&kuay);
            } else {
                $self->stop_time($client);
            }
        }

Caution, the timer of server is not as exactly as real clock, so I sync timer with the real clock at 4527 sec. This can lead to some bugs if your server is really relied on timer.

=head2 METHODs


=item new (\%hash)

the hash referece comprise
'server_name' name of your server, it also the pid filename
'port' the port you want to listen
'delimiter' delimiter of your protocol message
'timeout' timeout of idle client
'piddir' directory where pid file is kept

=item onClientConnected ($client)

      This method should be overrided. 
      It's triggered when a client connects to server.

=item onClientDisconnected ($client)

      This method should be overrided. 
      It's triggered when a client is disconnected, or disconnects itself from server.

=item onReceiveMessage ($client,$request)

      This method should be overrided. 
      It's triggered when a client send a message to server. 

=item start_turn ($client,$time,\&code)

      Start, turn counter. See Usage;

=item stop_time ($client)

      Stop, turn counter. See Usage;

=item disconnect_client ($client)

      Force, disconnect a client from server and call onClientDisconnected.

=item close_client ($client)

      Force, disconnect a client from server.

=item start ()

      When you setup every static such and such, you call this method to start listening.

=item getip ($client)

      Return ip address of one client.

=item getport ($client)

      Return port of one client.

=item piddir ()

      Return piddir of server.

=item serverName ()

      Return server_name of server.

=item port ()

      Return port of server.

=item sendmsg ($client,$message)

      Send $message to outgoing buffer for $client

=item cron ($time,\&code)

      Install timer triggered function. see Usage.

=item add_socket ($socket)

      Add a socket to the main non-blocking loop. The socket will be affected to the idle machanism like a client.(I'm too lazy to make it an optional)

=item select

      return an object of IO::Select of the main module,

=item nonblock ($socket)

      make $socket non-block

=head2 EXPORT

None.

=head1 AUTHOR

Komtanoo  Pinpimai <romerun@romerun.com>, yet another CP24, Bangkok, Thailand.

=head1 COPYRIGHT

Copyright 2002 (c) Komtanoo  Pinpimai <romerun@romerun.com>, yet another CP24, Bangkok, Thailand. All rights reserved.

=cut
