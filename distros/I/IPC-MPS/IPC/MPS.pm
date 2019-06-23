package IPC::MPS;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(spawn receive msg snd quit wt snd_wt listener open_node vpid2pid);

our $VERSION = '0.20';

use Carp;
use IO::Select;
use IO::Socket;
use Scalar::Util qw(refaddr);
use Storable qw(freeze thaw);


my $DEBUG = 0;
$DEBUG and require Data::Dumper;

my $sel = IO::Select->new();

my @spawn            = ();
my %msg              = ();
my %fh2vpid          = ();
my %vpid2fh          = ();
my %fh2fh            = ();
my $self_vpid        = 0;
my $self_parent_fh;
my $self_parent_vpid = 0;
my $self_parent_closed = 0;
my %listener         = ();
my %node             = ();
my %snd              = ();
my $ipc_loop         = 0; 
my $quit = 0;

my %vpid2pid = ();
sub vpid2pid { my ($vpid) = @_; $vpid2pid{$vpid} }

my @rcv    = ();
my %r_bufs = ();
my %w_bufs = ();

my %pack   = ();
my %unpack = ();

my %closed = ();

my $need_reset = 0;

my $blksize = 1024 * 16;


END {
	$ipc_loop or @spawn and carp "Probably have forgotten to call receive.";
	close $_ foreach values %fh2fh;
}

sub spawn(&) {
	my ($spawn) = @_;
	socketpair(my $child, my $parent, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";
	my $vpid = refaddr $child;
	push @spawn, [$vpid, $child, $parent, $spawn];
	return $vpid;
}


sub msg($$) {
	my ($msg, $sub) = @_;
	$msg{$msg} = $sub;
}


sub snd($$;@) {
	my ($vpid, $msg, @args) = @_;
	defined $vpid or carp("Argument vpid required"), return;
	defined $msg  or carp("Argument msg required"),  return;
	$vpid = $self_parent_vpid if $vpid == 0;
	$DEBUG and print "Send message '$msg' from $self_vpid to $vpid vpid in $self_vpid (\$\$=$$) with args: ", join(", ", @args), ".\n";
	push @{$snd{$vpid}}, [$self_vpid, $vpid, $msg, \@args];
	$closed{$vpid} = 1 if $msg eq "close" or $msg eq "exit";
	return 1;
}


sub quit() { $quit = 1 }


sub snd_wt($$;@) {
	my ($vpid, $msg, @args) = @_;
	defined $vpid or carp("Argument vpid required"), return;
	defined $msg  or carp("Argument msg required"),  return;
	snd($vpid, $msg, @args);
	wt($vpid, $msg);
}


sub listener($$;%) {
	my ($host, $port, %args) = @_;
	defined $host or carp("Argument host required"), return;
	defined $port or carp("Argument port required"), return;
	my $sock = IO::Socket::INET->new(Proto => 'tcp', Blocking => 0, LocalHost => $host, LocalPort => $port, Listen => 20, ReuseAddr => 1);
	if ($sock) {
		_pack_unpack($sock, %args) or return;
		$listener{$sock} = $sock;
		$sel->add($sock);
		return $sock;
	} else {
		carp "Cannot open socket '$host:$port' in $self_vpid: $!";
		return;
	}
}


sub open_node($$;%) {
	my ($host, $port, %args) = @_;
	defined $host or carp("Argument host required"), return;
	defined $port or carp("Argument port required"), return;
	my $sock = IO::Socket::INET->new(Proto => 'tcp', Blocking => 0);
    my $addr = sockaddr_in($port,inet_aton($host));
	$sock->sockopt(SO_KEEPALIVE, 1);
    my $rv = $sock->connect($addr);
	if ($rv) {
		_pack_unpack($sock, %args) or return;
		my $vpid = refaddr $sock;
		$node{$sock}     = $vpid;
		$fh2vpid{$sock}  = $vpid;
		$vpid2fh{$vpid}  = $sock;
		$fh2fh{$sock}    = $sock;
		$sel->add($sock);
		return $vpid;
	} else {
		carp "Cannot connect to socket '$host:$port' in $self_vpid: $!";
		return;
	}
}


sub _pack_unpack($%) {
	my ($fh, %args) = @_;
	if (my $pack = $args{pack} and my $unpack = $args{unpack}) {
		my $r = eval {
			my $r = $unpack->($pack->({a => ["b"]}));
			if (ref $r eq "HASH" and ref $$r{a} eq "ARRAY" and
				$$r{a}[0] and $$r{a}[0] eq "b")
			{
				return 1;
			} else {
				return 0;
			}
		};
		if (not $r or $@) {
			carp "False pack unpack test";
			return;
		}
		$pack{$fh}   = $pack;
		$unpack{$fh} = $unpack;
	} elsif ($args{pack} or $args{unpack}) {
		carp "pack and unpack is pair options";
		return;
	}
	return 1;
}


sub receive(&) {
	my ($receive) = @_;

	$DEBUG > 1 and print "Call receive in $self_vpid (\$\$=$$)\n";

	local $SIG{CHLD} = "IGNORE";
	local $SIG{PIPE} = "IGNORE";

	foreach (@spawn) {
		my ($vpid, $child, $parent, $spawn) = @$_;

		my $kid_pid = fork;
		defined $kid_pid or die "Can't fork: $!";

		unless ($kid_pid) {

			foreach (@spawn) {
				close $$_[1];
				close $$_[2] if $$_[2] ne $parent;
			}

			close $_ foreach values %fh2fh, values %listener;
			$sel = IO::Select->new();
			@spawn    = ();
			%listener = ();
			%node     = ();
			%msg      = ();
			%fh2vpid  = ();
			%vpid2fh  = ();
			%fh2fh    = ();
			%snd      = ();

			%vpid2pid = ();

			$ipc_loop = 0;

			@rcv    = ();
			%r_bufs = ();
			%w_bufs = ();

			%pack   = ();
			%unpack = ();

			%closed = ();

			$need_reset = 0;

			$self_parent_fh   = $parent;
			$self_parent_vpid = $self_vpid;

			$self_vpid        = $vpid;

			$fh2vpid{$self_parent_fh}   = $self_parent_vpid;
			$vpid2fh{$self_parent_vpid} = $self_parent_fh;
			$fh2fh{$self_parent_fh}     = $self_parent_fh;

			$sel->add($self_parent_fh);

			$spawn->();

			exit;
		}
		else {
			$vpid2pid{$vpid} = $kid_pid;
		}
	}


	foreach (@spawn) {
		my ($vpid, $child, $parent, $spawn) = @$_;
		close $parent;
		$fh2vpid{$child} = $vpid;
		$vpid2fh{$vpid}  = $child;
		$fh2fh{$child}   = $child;
		$sel->add($child);
	}
	@spawn = ();



	$receive->();



	unless ($ipc_loop) {
		$ipc_loop = 1;
		ipc_loop();
		$ipc_loop = 0;
	}
}


sub wt($$) {
	my ($waited_vpid, $waited_msg) = @_;
	defined $waited_vpid or carp("Argument vpid required"), return;
	defined $waited_msg  or carp("Argument msg required"),  return;
	$waited_vpid = $self_parent_vpid if $waited_vpid == 0;
	foreach my $i (0 .. $#rcv) {
		my ($from, $msg, $args)= @{$rcv[$i]};
		if ($from eq $waited_vpid and $msg eq $waited_msg) {
			splice @rcv, $i, 1;
			return wantarray ? @$args : $$args[0];
		}
	}
	$DEBUG and print "Start waiting for '$waited_vpid -> $waited_msg' in $self_vpid (\$\$=$$)\n";
	return ipc_loop($waited_vpid, $waited_msg);
}


sub ipc_loop(;$$) {
	my ($waited_vpid, $waited_msg) = @_;
	$DEBUG and print "Start ipc_loop in $self_vpid (\$\$=$$)\n";
	RESET: while ($sel->count() and not $quit) {

		foreach my $to (keys %snd) {
			if (@{$snd{$to}}) {
				my $fh = $vpid2fh{$to};
				unless ($fh) {
					if (@spawn) {
						carp "Probably have forgotten to call receive.";
						next;
					} else {
						if ($self_parent_fh) {
							unless ($self_parent_closed) {
								$fh = $self_parent_fh;
							} else {
								next;
							}
						} else {
							carp "The addressee $to is unknown or has left in $self_vpid (\$\$=$$)\n";
							next;
						}
					}
				}
				unless (exists $w_bufs{$fh}) {
					my $packet;
					if (my $pack = $pack{$fh}) {
						$packet = $pack->(shift @{$snd{$to}});
					} else {
						$packet = freeze  shift @{$snd{$to}};
					}
					my $buf = join "", pack("N", length $packet), $packet;
					$w_bufs{$fh} = $buf;
					$DEBUG and (@{$snd{$to}} or delete $snd{$to});
				}
			}
		}

		my $w_sel = IO::Select->new(map { $fh2fh{$_} } keys %w_bufs);

		if ($DEBUG > 1) {
			print "Select count from $self_vpid, sel->count=", $sel->count(), ", w_sel->count=", $w_sel->count(), "\n",
				$DEBUG > 2 ? Data::Dumper::Dumper({ snd => \%snd, r_bufs => \%r_bufs, w_bufs => \%w_bufs }) : "";
		}

		my ($can_read, $can_write, $has_exception)= IO::Select->select($sel, $w_sel, $sel);
		$DEBUG > 1 and print "Select from $self_vpid: ", scalar(@$can_read), " ", ($can_write ? scalar(@$can_write) : ""), " ", scalar(@$has_exception), "\n";

		foreach my $fh (@$can_read) {
			if ($listener{$fh}) {
				my $sock = $fh->accept;
				$pack{$sock}   = $pack{$fh};
				$unpack{$sock} = $unpack{$fh};
				$sock->sockopt(SO_KEEPALIVE, 1);
				my $vpid = refaddr $sock;
				$node{$sock}     = $vpid;
				$fh2vpid{$sock}  = $vpid;
				$vpid2fh{$vpid}  = $sock;
				$fh2fh{$sock}    = $sock;
				$sel->add($sock);
				next;
			}
			my $len = sysread $fh, (my $_buf), $blksize;
 			if ($len) {
				$r_bufs{$fh} .= $_buf;
				NEXT_MSG: {
					my $buf = $r_bufs{$fh};
					if (length $buf >= 4) {
						my $packet_length = unpack "N", substr $buf, 0, 4, "";
						if (length $buf >= $packet_length) {
							my $packet = substr $buf, 0, $packet_length, "";
							$r_bufs{$fh} = $buf || "";
							$DEBUG and ($r_bufs{$fh} or delete $r_bufs{$fh});

							my ($from, $to, $msg, $args);
							if (my $unpack = $unpack{$fh}) {
								($from, $to, $msg, $args) = @{$unpack->($packet)};
							} else {
								($from, $to, $msg, $args) = @{thaw $packet};
							}

							if ($node{$fh}) {
								$from = $node{$fh};
								$to   = $self_vpid;
							}

							$DEBUG and print "Got message '$msg' from $from to $to vpid in $self_vpid (\$\$=$$) with args: ", join(", ", @$args), ".\n";
							if ($to == $self_vpid) {
								$DEBUG and print "Run message sub '$msg' from $from to $to vpid in $self_vpid (\$\$=$$) with args: ", join(", ", @$args), ".\n";
								if (defined $waited_vpid and defined $waited_msg) {
									push @rcv, [$from, $msg, $args];
								} else {
									if ($msg{$msg}) {
										push @rcv, [$from, $msg, $args];
									} else {
										$DEBUG and print "Unknown message '$msg'\n";
									}
								}
							} elsif ($vpid2fh{$to}) {
								$DEBUG and print "Remittance message '$msg' from $from to $to vpid in $self_vpid (\$\$=$$) with args: ", join(", ", @$args), ".\n";
								push @{$snd{$to}}, [$from, $to, $msg, $args];
							} else {
								carp "Got Wandered message '$msg' from $from to $to in $self_vpid (\$\$=$$)\n";
							}

							redo NEXT_MSG if $r_bufs{$fh};
						}
					}
				}
 			} elsif (defined $len) {
 				$sel->remove($fh);
 				$w_sel->remove($fh);
				my $vpid = delete $fh2vpid{$fh};
				delete $vpid2fh{$vpid};
 				delete $r_bufs{$fh};
 				delete $w_bufs{$fh};
				delete $fh2fh{$fh};
				delete $vpid2pid{$vpid};
				delete $pack{$fh};
				delete $unpack{$fh};
				if (my $node_vpid = $node{$fh}) {
					delete $node{$fh};
					if ($msg{NODE_CLOSED}) {
						$msg{NODE_CLOSED}->($node_vpid, $fh->connected ? 1 : 0) unless $closed{$vpid};
					}
				} else {
					if ($msg{SPAWN_CLOSED}) {
						$msg{SPAWN_CLOSED}->($vpid) unless $closed{$vpid};
					}
				}
				delete $closed{$vpid};
 				close $fh;
				if ($self_parent_fh and $self_parent_fh eq $fh) {
					$self_parent_closed = 1;
					unless (defined $waited_vpid and defined $waited_msg) {
						unless (@rcv) {
							exit;
						}
					}
				}
 			} else {
 				$DEBUG and die "Can't read '$fh': $!";
 			}
		}


		if (defined $waited_vpid and defined $waited_msg) {
			foreach my $i (0 .. $#rcv) {
				my ($from, $msg, $args)= @{$rcv[$i]};
				if ($msg eq $waited_msg and $from eq $waited_vpid) {
					splice @rcv, $i, 1;
					$DEBUG and print "Stop waiting for '$waited_vpid -> $waited_msg' in $self_vpid (\$\$=$$)\n";
					$need_reset = 1;
					return wantarray ? @$args : $$args[0];
				}
			}
			unless (exists $vpid2fh{$waited_vpid}) {
				return;
			}
		} else {
			while (my $rcv = shift @rcv) {
				my ($from, $msg, $args)= @{$rcv};
				$msg{$msg}->($from, @$args) unless $closed{$from};
			}
		}
		if ($need_reset) {
			$need_reset = 0;
			next RESET;
		}


		foreach my $fh (@$can_write) {
			$fh2fh{$fh} or next;

			my $buf = $w_bufs{$fh};
			my $len = syswrite $fh, $buf, $blksize;
			if ($len) {
				substr $buf, 0, $len, "";
				if (length $buf) {
					$w_bufs{$fh} = $buf;
				} else {
					delete $w_bufs{$fh};
				}
			} else {
 				$DEBUG and die "Can't write to '$fh': $!";
			}
		}

	}
	$need_reset = 1;
	$quit = 0;
	return;
}



1;


__END__


=head1 NAME

IPC::MPS - Message Passing Style of Inter-process communication

=head1 SYNOPSIS

 use IPC::MPS;

 my $vpid = spawn {
 	receive {
 		msg ping => sub {
 			my ($from, $i) = @_;
 			print "Ping ", $i, " from $from\n";
 			snd($from, "pong", $i);
 		};
 	};
 };

 snd($vpid, "ping", 1);
 receive {
 	msg pong => sub {
 		my ($from, $i) = @_;
 		print "Pong $i from $from\n";
 		if ($i < 3) {
 			snd($from, "ping", $i + 1);
 		} else {
 			exit;
 		}
 	};
 };

=head1 DESCRIPTION

The messaging system between parental and child processes, and between child processes, that have the same parent.

Moto: inter-process communication without blocking.

=head2 Concurrency programming

The peculiarity of the system is that the messaging between child processes is handled by the parents.
That is why we recommend using the parental processes just to coordinate the working process and to store data.

The messages are handled by the UNIX sockets.

 $vpid = spawn {
    ...
    receive {
      msg "name" => sub {
        my ($from, @args) = @_;
        ...
      };
      msg "name" => sub { ... };
      msg "name" => sub { ... };
      ...
    };
  };


Child processes are created not when spawn is called, they are created later when receive is called, just before send-receive cycle is called. It is necessary so that all vpid are defined by fork call. vpid is an address of the link to the socket from main process to the child one.

Other spawn may be created inside spawn.
If spawn is created inside receive, receive also must be called to start child processes. New receive will add its information to the old one and pass the control to the old receive messaging cycle.

The message sending.

 snd($vpid, "msg name", @args);

if vpid = 0 , this is a message to the parental process.

If the parental process is over, the child process ends too.

To detect spawn closing message SPAWN_CLOSED handler should be defined:

 msg SPAWN_CLOSED => sub {
 	my ($vpid) = @_;
 	...
 };

Note, for your convenience "close" and "exit" messages are special.
If a process is sent a "close" or "exit" message, then any messages from it are ignored, SPAWN_CLOSED and NODE_CLOSED too.

To break receive use "quit" subroutine.

The vpid2pid function accepts the vpid argument and returns OS PID. Importnat! PID will be available only after the receive subroutine is called.

=head2 Dataflow programming

Sometimes you may need to get additional information from other processes and only then continue the message processing. For this you may send a message with information request and then wait information getting in a proper place by subprogram wt (abbreviated "wait"), without current message processing break.

 snd("vpid_1", "msg_1", @args_1);
 snd("vpid_2", "msg_2", @args_2);

 my $r = wt("vpid_1", "msg_1");
 ...
 my @r = wt("vpid_2", "msg_2");

Subprogram wt starts new waiting cycle, sending of old messages continues and receiving of new messages starts, but new messages are not processed, they are accumulated in a buffer. When the response to a needed message is received, this waiting cycle ends and wt returns the response --- the processing of the initial message continues.

 my $r = snd_wt($vpid, $msg, @args);

is a shortening for:

 snd($vpid, $msg, @args);
 my $r = wt($vpid, $msg);

=head2 The main differences from Erlang

Attention, this is not Erlang, this is Perl IPC::MPS. The main differences, subsequent upon one another:

=over

=item 1

Full operating system processes.

=item 2

Subprogram 'spawn' doesn't create processes directly, it just performs the preparative operations. The processes are created when 'receive' is called.

=item 3

'Receive' is repeated, not a one-time as in Erlang.

=item 4

'Receive' inside 'receive' doesn't supersede the previous one, but adds a new message handlers and starts new processes.

=item 5

To wait the response to a specific message inside handler, subprogram 'wt' should be used. In Erlang it is done with the same 'receive'.

=back

=head2 Distributed Programming

To transform the current process to a node you need to call 'listener' subprogram:

 listener($host, $port);

Connecting to the remote node is done with 'open_node' subprogram:

 my $vpid = open_node($host, $port);

You may set youself pack and unpack functions, instead of freeze and thaw functions of Storable module:

             listener($host, $port, pack => sub { ... }, unpack => sub { ... });
 my $vpid = open_node($host, $port, pack => sub { ... }, unpack => sub { ... });

To detect connection closing message NODE_CLOSED handler should be defined:

 msg NODE_CLOSED => sub {
 	my ($vpid, $connected) = @_;
	if ($connected) {
 		print "Node closed.\n";
 	} else {
 		print "Cannot connect to node: $!.\n";
 	}
 	...
 };

This statement is true for both the client and the server.

=head1 EXAMPLES

=head2 Ping Pong

 use IPC::MPS;

 my $ping_pong = 3;

 my ($vpid1, $vpid2);

 $vpid1 = spawn {
 	snd($vpid2, "ping", 1);
 	receive {
 		msg pong => sub {
 			my ($from, $i) = @_;
 			print "Pong $i from $from\n";
 			if ($i < $ping_pong) {
 				snd($from, "ping", $i + 1);
 			} else {
 				snd(0, "exit");
 			}
 		};
 	};
 };

 $vpid2 = spawn {
 	receive {
 		msg ping => sub {
 			my ($from, $i) = @_;
 			print "Ping ", $i, " from $from\n";
 			snd($from, "pong", $i);
 		};
 	};
 };

 receive {
 	msg exit => sub {
 		print "EXIT\n";
		exit;
 	};
 };

=head2 Triplex circular Ping Pong

 use IPC::MPS;

 my $ping_pong = 5;

 sub ping_pong($) {
 	my $vpid = shift;
 	sub {
 		msg ping => sub {
 			my ($from, @args) = @_;
 			print "Ping ", $args[0], " from $from\n";
 			snd($from, "pong", $args[0]);
 			if ($args[0] < $ping_pong) {
 				snd($vpid, "ping", $args[0] + 1, $$);
 			}
 		};
 		msg pong => sub {
 			my ($from, @args) = @_;
 			print "Pong ", $args[0], " from $from\n";
 			unless ($args[0] < $ping_pong) {
 				snd(0, "exit");
 			}
 		};
 	};
 }


 my ($vpid1, $vpid2, $vpid3);

 $vpid1 = spawn {
 	snd($vpid2, "ping", 1, $$);
 	receive { ping_pong($vpid2)->() };
 };

 $vpid2 = spawn {
 	receive { ping_pong($vpid3)->() };
 };

 $vpid3 = spawn {
 	receive { ping_pong($vpid1)->() };
 };


 receive {
 	msg exit => sub {
 		print "EXIT\n";
		exit;
 	};
 };

=head2 Tree

 use IPC::MPS;

 my $vpid1 = spawn {

 	my $vpid2 = spawn {
 		receive {
 		 	msg hello2 => sub {
 		 		print "Hello 2\n";
 		 	};
 		};
 	};

 	receive {
 		msg hello1 => sub {
 			print "Hello 1\n";
 			snd($vpid2, "hello2");

 			my $vpid3 = spawn {
 				receive {
 					msg hello3 => sub {
 						print "Hello 3\n";
 					};
 				};
 			};

 			snd($vpid3, "hello3");
 			receive {};
 		};
 	};
 };

 spawn {
 	sleep 1;
 	print "SLEEP\n";
 	snd(0, "exit");
 	receive {};
 };

 snd($vpid1, "hello1");
 receive {
 	msg exit => sub {
 		print "EXIT\n";
 		exit;
 	};
 };

=head2 Waiting

Waiting for a response to a specific message.

 use IPC::MPS;

 my $vpid = spawn {
 	receive {
 		msg foo => sub {
 			my ($from, $text) = @_;
 			print "foo: $text\n";

 			snd(0, "too", 1);
 			print "too -> baz\n";

 			my $rv = wt(0, "baz");
 			print "baz: $rv\n";

 			my @rv = snd_wt(0, "sugar", $rv);
 			print "sugar: $rv[0]\n";

 			exit;
 		};
 	};
 };


 snd($vpid, "foo", "Hello, wait");

 receive {
 	msg too => sub {
 		my ($from, $i) = @_;
 		print "too: $i\n";
 		snd($from, "baz", ++$i);
 	};
 	msg sugar => sub {
 		my ($from, $i) = @_;
 		snd($from, "sugar", ++$i);
 	};
 };

=head1 DEMO

See directory demo.

=head1 REALISATIONS

=over

=item *

L<IPC::MPS> based on L<IO::Select>.

=item *

L<IPC::MPS::Event> based on L<Event>.

=item *

L<IPC::MPS::EV> based on L<EV>.

=back

=head1 Compatibility with Event, EV, AnyEvent based modules

IPC::MPS::Event and IPC::MPS::EV allows usage of side modules based on Event, EV modules accordingly (directly or thru AnyEvent).

=head2 Timer

 use IPC::MPS::Event;
 use Event;

 my $vpid = spawn {
 	receive {
 		msg ping => sub {
 			my ($from, $hello) = @_;
 			print "$hello; $$\n";
 			Event->timer(after => 1, cb => sub {
 				snd($from, "pong", "hy");
 			});
 		};
 	};
 };

 snd($vpid, "ping", "hello");

 receive {
 	msg pong => sub {
 		my ($from, $hello) = @_;
 		print "$hello; $$\n";
 		print "EXIT\n";
 		exit;
 	};
 };

=head2 AnyEvent::HTTP

 use IPC::MPS::Event;
 use AnyEvent::HTTP;

 my $vpid = spawn {
 	receive {
 		msg req => sub {
 			my ($from, $url) = @_;
 			http_get $url, sub {
 				print ${$_[1]}{URL}, "\t", ${$_[1]}{Status}, "; $$\n";
 				snd($from, "res", $url, ${$_[1]}{Status});
 			};
 		};
 	};
 };

 snd($vpid, "req", "http://localhost/");

 receive {
 	msg res => sub {
 		my ($from, $url, $status) = @_;
 		print "$url\t$status; $$\n";
 		print "EXIT\n";
 		exit;
 	};
 };

=head1 SEE ALSO

Sometimes it is easier to use a module L<BGS> - Background execution of subroutines in child processes.

=head1 AUTHOR

Nick Kostyria

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Nick Kostyria

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
