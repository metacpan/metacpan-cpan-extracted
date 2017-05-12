use strict;
package Event::tcpsession;
use Carp;
use Symbol;
use Socket;
use Ioctl qw(FIONBIO);
use Errno qw(EAGAIN);
use Event 0.61;
use Event::Watcher qw(R W T);
require Event::io;
use base 'Event::io';
use vars qw($VERSION);
$VERSION = '0.14';

use constant DEBUG_SHOW_RPCS => 0;
use constant DEBUG_BYTES => 0;

use constant PROTOCOL_VERSION => 2;
use constant RECONNECT_TM => 3;

use constant HEADER_FORMAT => 'Nn';

# special message IDs
use constant NOREPLY_ID     => 0;
use constant APIMAP_ID      => 1;
use constant RESERVED_IDS   => 2;

'Event::Watcher'->register;

# API is an ordered array:
# { name => 'opname', code => sub {}, req => 'nn' }
# { name => 'opname', code => sub {}, req => 'nn', reply => 'nn' }

sub new {
    my ($class, %p) = @_;
    my @passthru;
    push @passthru, desc => $p{desc} if
	exists $p{desc};
    my $o = $class->SUPER::new(parked => 1, reentrant => 0, @passthru);
    $o->{status_cb} = $p{cb} || sub {};
    $o->{api} = $p{api} || [];
    $o->{delayed} = [];
    $o->{q} = [];     # message queue
    $o->{pend} = {};  # pending transactions
    $o->{next_txn} = $$;
    $o->set_peer(can_ignore => 1, %p);
    $o;
}

sub is_server_side { # make function call XXX
    my ($o) = @_;
    !exists $o->{iaddr}
}

# Transaction IDs are for keeping track of roundtrip messaging.
# They are also used for special messages.  Special messages
# only use low-order IDs.  The special range from
# [0x8000, 0x8000 + RESERVEDIDS) is unused.
#
# use 1 bit to distinguish short/long messages? XXX
#
sub get_next_transaction_id {
    my ($o) = @_;
    $o->{next_txn} = ($o->{next_txn}+1) & 0x7fff;
    $o->{next_txn} = RESERVED_IDS if $o->{next_txn} < RESERVED_IDS;
    $o->{next_txn} | ($o->is_server_side ? 0x8000 : 0);
}

#########################################################################

sub fd {
    if (@_ == 1) {
	shift->SUPER::fd;
    } else {
	my ($o, $fd) = @_;
	if (caller eq __PACKAGE__) {
	    if ($fd) {
		ioctl $fd, FIONBIO, pack('l', 1)
		    or die "ioctl FIONBIO: $!";
		#setsockopt($c->{e_fd}, IPPROTO_TCP, TCP_NODELAY, pack('l',1))
		# or die "setsockopt: $!";
	    }
	    $o->SUPER::fd($fd)
	} else {
	    if (!defined $fd) {
		# This is a special case for regression testing.
		# Who knows, maybe it is generally useful too.
		close $o->fd;
		$o->SUPER::fd(undef)
	    } else {
		$o->set_peer(fd => $fd);
	    }
	}
    }
}

sub cb {
    if (caller eq __PACKAGE__) {
	shift->SUPER::cb(@_);
    } else {
	my $o = shift;
	if (@_ == 0) {
	    $o->{status_cb}
	} else {
	    $o->{status_cb} = shift;
	}
    }
}

#########################################################################

sub set_peer {
    my ($o,%p) = @_;

    croak "set_peer: '".$o->desc."' already connected"
	if $o->{peer_set};

    if (exists $p{port}) {
	#client side

	my $iaddr;
	if (exists $p{host}) {
	    my $host = $p{host};
	    $iaddr = inet_aton($host) || die "Lookup of host '$host' failed";
	} elsif (exists $p{iaddr}) {
	    $iaddr = $p{iaddr};
	    warn "Both iaddr & host given; host ignored" if exists $p{host};
	} else {
	    $iaddr = inet_aton('localhost');
	}
	my $port = $p{port};
	
	$o->{iaddr} = $iaddr;
	$o->{port} = $port;

	$o->{status_cb}->($o, 'not available')
	    if !$o->connect_to_server;

    } elsif (exists $p{fd}) {
	#server side

	$o->fd($p{fd});
	$o->reconnected;
	
    } else {
	return
	    if $p{can_ignore};
	croak("connect to what?");
    }
    $o->{peer_set} = 1;
}

sub disconnect {
    my ($o, $why) = @_;
    if ($o->is_server_side) {
	# recovery is always client's responsibility
	$o->cancel;
	return 1;
    }
    $o->{status_cb}->($o, 'disconnect', $why);
    $o->connect_to_server;
}

sub connect_to_server {
    my ($o) = @_;
    $o->fd(undef);
    my $fd = gensym;
    socket($fd, PF_INET, SOCK_STREAM, getprotobyname('tcp'))
	or die "socket: $!";
    if (!connect($fd, sockaddr_in($o->{port}, $o->{iaddr}))) {
	$o->{status_cb}->($o, 'connect', $!);
	$o->timeout(RECONNECT_TM);
	$o->cb([$o,'connect_to_server']);
	$o->start;
	return
    }
    $o->fd($fd);
    $o->{status_cb}->($o, 'connect');
    $o->reconnected;
    1
}

sub reconnected {
    my ($o) = @_;

    $o->timeout(undef);
    delete $o->{pend};
    delete $o->{peer_version};
    delete $o->{peer_api};
    delete $o->{peer_opname};

    $o->{ibuf} = '';
    $o->{obuf} = pack 'n', PROTOCOL_VERSION;

    append_obuf($o, APIMAP_ID, join("\n", map {
	my @z = ($_->{name}, $_->{req} || '');
	push @z, $_->{reply} || '' if exists $_->{reply};
	join($;, @z);
    } @{$o->{api}}));

    # reload pending transactions
    # (anything not requiring acknowledgement gets/got ignored)
    while (my ($tx,$i) = each %{$o->{pend}}) {
	# warn "pend $i->[0]{name}";
	append_obuf($o, $tx, $i->[2]);
    }

    $o->poll(R|W);
    $o->cb([$o,'service']);
    $o->start;
}

#########################################################################

sub append_obuf {    # function call
    my ($o, $tx, $m) = @_;
    # length is inclusive
    my $mlen = length $m;
    $o->{obuf} .= pack(HEADER_FORMAT, 6+$mlen, $tx) . $m;

    $o->poll($o->poll | W);
}

sub pack_args {
    my $template = shift;
    if ($template) {
	pack $template, @_;
    } elsif (@_ == 0) {
	''
    } elsif (@_ == 1) {
	$_[0]
    } else {
	undef
    }
}

sub unpack_args {
    my ($template, $bytes) = @_;
    if ($template) {
	unpack $template, $bytes
    } elsif (length $bytes) {
	$bytes
    } else {
	()
    }
}

sub service {
    my ($o, $e) = @_;
    my $w = $e->w;
    return $o->disconnect("inactivity")
	if $e->got & T;
    return $o->disconnect("fd closed")
	if !defined $w->fd;
    if ($e->got & R) {
	my $buf = $o->{ibuf};
	while (1) {
	    my $ret = sysread $w->fd, $buf, 8192, length($buf);
	    next if $ret;
	    last if $!{EAGAIN};
	    return $o->disconnect("sysread ret=$ret, $!");
	}
	#warn "$$:R:".unpack('h*', $buf).":";
	# decode $buf
	if (!exists $o->{peer_version} and length $buf >= 2) {
	    # check PROTOCOL_VERSION ...
	    $o->{peer_version} = unpack 'n', substr($buf, 0, 2);
	    warn "$$:peer_version=$o->{peer_version}"
		if DEBUG_SHOW_RPCS;
	    $buf = substr $buf, 2;
	    $o->disconnect("peer version mismatch $o->{peer_version} != ".
			   PROTOCOL_VERSION)
		if $o->{peer_version} != PROTOCOL_VERSION;
	}
	while (length $buf >= 6) {
	    my ($len, $tx) = unpack HEADER_FORMAT, $buf;
	    last if length $buf < $len;  # got a complete message?
	    my $m = substr $buf, 6, $len-6;

	    $buf = substr $buf, $len; # snip

	    if ($tx == NOREPLY_ID) {
		my $opid = unpack 'n', $m;
		$m = substr $m, 2;
		my $api = $o->{api}[$opid];
		if (!$api) {
		    warn "API $opid not found (ignored)";
		    next
		}
		# EVAL
		my @args = unpack_args($api->{req}, $m);
		warn "$$:Run($opid)(".join(', ', @args).")"
		    if DEBUG_SHOW_RPCS;
		$api->{code}->($o, @args);

	    } elsif ($tx < RESERVED_IDS) {
		if ($tx == APIMAP_ID) {
		    my @api;
		    for my $packedspec (split /\n/, $m) {
			my @spec = split /$;/, $packedspec, -1;
			if (@spec == 2 or @spec == 3) {
			    my @p=( name => $spec[0], req => $spec[1]);
			    push @p, reply => $spec[2]
				if @spec == 3;
			    push @api, { @p };
			} else {
			    warn "got strange API spec: ".join(', ',@spec);
			}
		    }
		    warn "$$: ".(0+@api)." APIs"
			if DEBUG_SHOW_RPCS;
		    $o->{peer_api} = \@api;
		    my %peer_opname;
		    for (my $x=0; $x < @api; $x++) {
			$peer_opname{$api[$x]{name}} = $x;
		    }
		    $o->{peer_opname} = \%peer_opname;
		    for my $rpc (@{$o->{delayed}}) {
			$o->rpc(@$rpc);
		    }
		    $o->{delayed} = [];
		} else {
		    die "Unknown TX $tx?";
		}
	    } else {
		if ($tx >= 0x8000 xor $o->is_server_side) {
		    my $opid = unpack 'n', $m;
		    $m = substr $m, 2;
		    my $api = $o->{api}[$opid];
		    if (!$api) {
			warn "API $opid not found (ignored)";
			next
		    }
		    # EVAL
		    my @args = unpack_args($api->{req}, $m);
		    warn "$$:Run($opid)(".join(", ", @args).") returning..."
			if DEBUG_SHOW_RPCS;
		    my @ret = $api->{code}->($o, @args);
		    # what if exception? XXX
		    warn "$$:Return($opid)(".join(", ", @ret).")"
			if DEBUG_SHOW_RPCS;
		    my $packed_ret = pack_args($api->{reply}, @ret);
		    warn("'$api->{name}' returned (".join(', ',@ret).
			 " yet doesn't have a reply pack template")
			if !defined $packed_ret;
		    append_obuf($o, $tx, pack('n',$opid).$packed_ret);
		    
		} else {
		    my $pend = $o->{pend}{$tx};
		    if (!$pend) {
			warn "Got unexpected reply for TXN $tx (ignored)";
			next;
		    }
		    my ($api,$cb) = @$pend;
		    my $opid = unpack 'n', $m; # can double check opid XXX
		    # EVAL
		    my @args= unpack_args($api->{reply}, substr($m, 2));
		    warn "$$:RunReply($opid)(".join(", ", @args).")"
			if DEBUG_SHOW_RPCS;
		    $cb->($o, @args);
		}
	    }
	}
	$o->{ibuf} = $buf;
    }
    if (length $o->{obuf}) {
	my $buf = $o->{obuf};
	my $sent = syswrite($w->fd, $buf, length($buf), 0);
	if ($!{EAGAIN}) {
	    $sent ||= 0;
	} elsif (!defined $sent) {
	    return $o->disconnect("syswrite: $!")
	}
	if ($sent) {
	    warn "$$:W:".unpack('h*', substr($buf, 0, $sent)).":"
		if DEBUG_BYTES;
	    $buf = substr $buf, $sent;
	    $o->{obuf} = $buf;
	}
    }
    if (length $o->{obuf}) {
	$o->poll($o->poll | W);
    } else {
	$o->poll($o->poll & ~W);
	if (keys %{$o->{pend}}) {
	    # close connection if a timeout is exceeded
	}
    }
}

sub rpc {
    my $o = shift;
    if (!defined $o->fd or !exists $o->{peer_opname}) {
	my @copy = @_;
	#my $fileno = $o->fd? fileno($o->fd) : 'undef';
	#warn "$$: delay $copy[0] ($fileno, $o->{peer_opname})";
	push @{$o->{delayed}}, \@copy;
	return;
    }
    my $opname = shift;
    confess "No opname?"
	if !$opname;
    my $id = $o->{peer_opname}{$opname};
    croak "'$opname' not found on peer (".
	join(' ', sort keys %{$o->{peer_opname}}).")"
	    if !defined $id;

    my $api = $o->{peer_api}[$id];

    # prepare for reply (if any)
    my $tx;
    my $save;
    if (!exists $api->{reply}) {
	$tx = NOREPLY_ID;
    } else {
	$tx = $o->get_next_transaction_id;
	die "too many pending transactions"
	    if exists $o->{pend}{$tx};
	$save = $o->{pend}{$tx} = [$api, shift];
    }

    warn "$$:Call($id)(".join(", ", @_).")"
	if DEBUG_SHOW_RPCS;
    my $packed_args = pack_args($api->{req}, @_);
    croak("Attempt to invoke '$opname' with (".join(', ', @_).
	  ") without pack template")
	if !defined $packed_args;

    my $packed_msg = pack('n', $id).$packed_args;
    $save->[2] = $packed_msg
	if $save;
    append_obuf($o, $tx, $packed_msg);
}

1;
__END__

=head1 NAME

Event::tcpsession - reliable bidirectional RPC session layer

=head1 SYNOPSIS

    my $api = [
	   { name  => 'my_rpc',
	     req   => 'nN',                 # network short, network long
             reply => '',                   # no translator for reply
             code  =>
	       sub { 'returned to caller' } # server-side code
           },
	   ...
	      ];

    Event->tcpsession(fd => $socket, api => $api);

=head1 DESCRIPTION

Automatic client-side recovery.

Embedded NULLs are OK.

What are the arbitrary limits?

=head1 SUPPORT

If you have insights or complaints then please subscribe to the
mailing list!  Send email to:

  majordomo@perl.org

The body of your message should read: 

  subscribe perl-loop

This list is archived at

  http://www.xray.mpe.mpg.de/mailing-lists/perl-loop/

Thanks!

=head1 COPYRIGHT

Copyright © 1999 Joshua Nathaniel Pritikin.  All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
