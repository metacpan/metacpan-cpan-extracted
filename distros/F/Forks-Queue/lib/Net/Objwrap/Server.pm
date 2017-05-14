package Net::Objwrap::Server;
use 5.012;
use strict;
use warnings;
eval "use Sys::HostAddr";  # recommended
use Scalar::Util 'reftype';
use Socket;
use POSIX ':sys_wait_h';
use Carp;
require overload;
use File::Temp;

our $VERSION = '0.08';
our %DEFAULT = (idle_timeout => 30, keep_alive => 30, alarm_freq => 5);

END {
    if (our $IS_TEST && $^O eq 'MSWin32') {
        SHUTDOWN();
    }
}

sub serialize    { goto &Net::Objwrap::serialize }
sub deserialize  { goto &Net::Objwrap::deserialize }
sub xdiag { goto &Net::Objwrap::xdiag }

sub new {
    my ($pkg, $opts, $file, @obj) = @_;

    my $host = $INC{'Sys/HostAddr.pm'}
        ? Sys::HostAddr->new->main_ip
        : $ENV{HOSTNAME} // qx(hostname) // "localhost";
    chomp($host);
    socket(my $socket, Socket::PF_INET(), Socket::SOCK_STREAM(),
           getprotobyname("tcp")) || croak "socket: $!";
    setsockopt($socket, Socket::SOL_SOCKET(), Socket::SO_REUSEADDR(),
               pack("l",1)) || croak "setsockopt: $!";
    my $sockaddr = Socket::pack_sockaddr_in(0, Socket::inet_aton($host));
    bind($socket,$sockaddr) || croak "bind: $!";
    listen($socket, Socket::SOMAXCONN()) || croak "listen: $!";
    $sockaddr = getsockname($socket);
    my ($port,$addr) = Socket::unpack_sockaddr_in($sockaddr);

    my $meta = {
        sockaddr => $sockaddr,
        socket => $socket,
        host => $host,
        host2 => Socket::inet_ntoa($addr),
        port => $port,

        pid_file => $^O eq 'MSWin32' ? (File::Temp::tempfile())[1] : "",
        creator_pid => $$,

        idle_timeout => $opts->{idle_timeout} // $DEFAULT{idle_timeout},
        keep_alive => time + ($opts->{keep_alive} // $DEFAULT{keep_alive}),
    };

    my @store;
    my $obj = {};

    foreach my $o (@obj) {
        my ($num,$str);
        {
            no overloading;
            $str = "$o";
            $num = hex($str =~ /x(\w+)/);
        }
	my $reftype = reftype($o);
	my $ref = ref($o);
	
	my $store = {
	    ref => $ref,
	    reftype => $reftype,
	    id => $num,
	};
	$obj->{$num} = $o;
	
	if (overload::Overloaded($o)) {
            $store->{overload} = _overloads($o);
        }
        push @store, $store;
    }

    my $self = bless { meta => $meta, store => \@store, obj => $obj},
               __PACKAGE__;
    write_config_file($file,$self);
    my $pid = fork();
    if (!defined($pid)) {
        croak "fork: $!";
    }
    if ($pid == 0) {
        if ($self->{meta}{pid_file}) {
            open my $fh, ">>", $self->{meta}{pid_file};
            print $fh "$$\n";
            close $fh;
        }
        $self->process_requests;
	xdiag "server is done processing requests t=",time-$^T;
        exit;
    }
    $self->{meta}{server_pid} = $pid;
    our @SERVERS;
    push @SERVERS, $self;
    return $self;
}

# return list of operators that are overloaded on the given object
sub _overloads {
    my $obj = shift;
    if (overload::Overloaded($obj)) {
        my @overloads;
        foreach my $opses (values %overload::ops) {
            push @overloads, grep overload::Method($obj,$_),split ' ',$opses;
        }
        return \@overloads;
    } else {
        return;
    }
}

# we should not send any serialized references to the client.
# Any references in a response should be replaced with 'object ids'
# -- handles that the client may use to obtain further information
# about the object from the server.
sub convert_ref {
    my ($self,$resp,$obj) = @_;
    return $obj unless ref($obj);

    my $id = do {
        no overloading;
        0 + $obj;
    };
    if (!$self->{obj}{$id}) {
        $self->{obj}{$id} = $obj;
        $resp->{meta}{$id} = {
            id => $id, ref => ref($obj), reftype => reftype($obj)
        };
        if (overload::Overloaded($obj)) {
            $resp->{meta}{$id}{overload} = _overloads($obj);
        }
    }
    #    return bless \$id,'Net::Objwrap::ObjectID';
    return \$id;
}

# before the response is serialized, any references in the response
# should be converted to 'object ids'
sub serialize_response {
    my ($self,$resp) = @_;
    if ($resp->{context}) {
        if ($resp->{context} == 1) {
            $resp->{response} = $self->convert_ref($resp,$resp->{response});
        } elsif ($resp->{context} == 2) {
            $resp->{response} = [
                map $self->convert_ref($resp,$_), @{$resp->{response}}  ];
        }
    }
    return serialize($resp);
}

sub write_config_file {
    my ($file, $server) = @_;
    if ($file) {
        open(my $fh, '>', $file) || croak "write_config_file '$file': $!";
        print $fh serialize( {
	    host => $server->{meta}{host},
	    port => $server->{meta}{port},
	    store => $server->{store}
		      } );
        close $fh;
	xdiag "server: Wrote config file $file";
        return 1;
    }
    return;
}

sub still_active {
    my $self = shift;
    my $meta = $self->{meta};
    return 1 if time <= $meta->{keep_alive};
    return 1 if keys %{$meta->{pids}};
    return 1 if time < $meta->{last_connection} + $meta->{idle_timeout};
    return;
}

sub SHUTDOWN {
    our @SERVERS;
    for my $server (@SERVERS) {
        if ($$ == $server->{meta}{creator_pid}) {
            $server->shutdown;
        }
    }
}

sub shutdown {
    my $server = shift;
    if ($server->{meta}{pid_file}) {
        $Net::Objwrap::XDEBUG &&
            print STDERR "Server pids in $server->{meta}{pid_file}\n";
        open my $fh, '<', $server->{meta}{pid_file};
        my @pids = <$fh>;
        chomp @pids;
        close $fh;
        $Net::Objwrap::XDEBUG && print STDERR "Killing server pids @pids\n";
        kill 'KILL', @pids;
        if (unlink $server->{meta}{pid_file}) {
            delete $server->{meta}{pid_file};
        }
    }
}

sub process_requests {
    my $self = shift;
    my $meta = $self->{meta};
    my $finished = 0;
    $meta->{last_connection} = time;

    $SIG{CHLD} = sub {
        while ((my $pid=waitpid(-1,WNOHANG())) > 0 && WIFEXITED($?)) {
            delete $meta->{pids}{$pid};
        }
        ++$finished unless $self->still_active;
    };
    $SIG{ALRM} = sub {
        while ((my $pid=waitpid(-1,WNOHANG())) > 0 && WIFEXITED($?)) {
            delete $meta->{pids}{$pid};
        }
        ++$finished unless $self->still_active;
        alarm ($DEFAULT{alarm_freq} || 5);
    };

    while (!$finished) {
        alarm ($DEFAULT{alarm_freq} || 5);
        my $client;
        my $server = $meta->{socket};
        my $paddr = accept($client,$server);
        if (!$paddr) {
            if (!$self->still_active) {
                $finished++;
                last;
            }
            if ($!{EINTR} || $!{ECHILD}) {
                next;
            }
            croak "accept: $!";
        }
	xdiag "server: accepted new connection";

        $meta->{last_connection} = time;
        my $pid = fork();
        if (!defined($pid)) {
            croak "fork after accept: $!";
        }
        if ($pid != 0) {
            if ($meta->{pid_file}) {
                open my $fh, ">>", $meta->{pid_file};
                print $fh "$$\n";
                close $fh;
            }
            $meta->{pids}{$pid}++;
            next;
        }

        # grandchild to handle client connection
        alarm 0;
        $SIG{CHLD} = $SIG{ALRM} =
            sub { warn "don't expect SIG$_[0] in grandchild" };
        local $Net::Objwrap::Server::disconnect = 0;

        my $fh_sel = select $client;
        $| = 1;
        select $fh_sel;

        while (my $req = <$client>) {
            next unless $req =~ /\S/;
	    xdiag "server: received new request: $req";
            my $resp = $self->process_request($req);
            $resp = $self->serialize_response($resp);
	    xdiag "server: response is: '$resp'";
            print {$client} $resp,"\n";
            last if $Net::Objwrap::disconnect;
        }
        close $client;
	# this isn't where the cygwin segfault is
        exit;
    }
    xdiag "server: shutting down";
    close $meta->{socket};
    xdiag "server: shut down at ",time-$^T;
    return;
}

sub process_request {
    my ($self, $request) = @_;
    croak "process_request: invalid non-scalar request" if ref($request);

    xdiag("server received request: '$request'");

    $request = deserialize($request);
    my $topic = $request->{topic};
    my $cmd = $request->{command};
    my $has_args = $request->{has_args} // 0;
    my $args = $request->{args};
    my $ctx = $request->{context};
    my $id = $request->{id};

    if (!defined($topic)) {
        Carp::confess "request without topic:  $_[1]";
    }
    
    if ($topic eq 'META') {
        if ($cmd eq 'disconnect') {
            $Net::Objwrap::Server::disconnect = 1;
            return {disconnect_ok => 1};
        } else {
            my $obj = $self->{obj}{$id};
            if ($cmd eq 'ref') {
                return { context => 1, response => ref($obj) };
            } elsif ($cmd eq 'reftype') {
                return { context => 1, response => reftype($obj) };
            } else {
                return { error =>
                     "Net::Objwrap: unsupported meta command '$cmd'" };
            }
        }
    }

    elsif ($topic eq 'HASH') {
	my $obj = $self->{obj}{$id};
        if (reftype($obj) ne 'HASH') {
            return { error => 'Not a HASH reference' };
        }
        my $resp = eval { $self->process_request_HASH(
			      $obj,$cmd,$has_args,$args) };
	if ($@) {
	    $resp = { error => $@ };
	}
	return $resp;
    }

    elsif ($topic eq 'ARRAY') {
        my $obj = $self->{obj}{$id};
        if (reftype($obj) ne 'ARRAY') {
            return { error => 'Not an ARRAY reference' };
        }
        my $resp = eval {
	    $self->process_request_ARRAY($obj,$cmd,$has_args,$args,$ctx);
	};
	if ($@) {
	    $resp = { error => $@ };
	}
	return $resp;
    }

    elsif ($topic eq 'SCALAR') {
        my $obj = $self->{obj}{$id};
	if (reftype($obj) ne 'SCALAR') {
	    return { error => 'Not a SCALAR reference' };
	}
	my $resp = eval {
	    $self->process_request_SCALAR($obj,$cmd,$has_args,$args);
	};
	if ($@) {
	    $resp = { error => $@ };
	}
	return $resp;
    }

    elsif ($topic eq 'METHOD') {
        my @r;
        my $obj = $self->{obj}{$id};
        if ($ctx < 2) {
            @r = scalar eval { $has_args ? $obj->$cmd(@$args)
                                         : $obj->$cmd };
        } else {
            @r = eval { $has_args ? $obj->$cmd(@$args)
                            : $obj->$cmd  };
        }
        if ($@) {
            return { error => $@ };
        }
        if ($ctx == 2) {
            return { context => 2, response => \@r };
        } elsif ($ctx == 1 && defined $r[0]) {
            return { context => 1, response => $r[0] };
        } else {
            return { context => 0 };
        }
    }

    elsif ($topic eq 'overload') {
        my $resp = $self->process_request_overload(
                       $self->{obj}{$id},$cmd,$args->[0],$args->[1]);
        xdiag("response for overload is '$resp'");
        return $resp;
    }

    my $error = __PACKAGE__ . ": unrecognized topic '$topic' from client";
    return { error => $error };
}

sub process_request_overload {
    my ($self,$x,$op,$y,$swap) = @_;
    if ($swap) {
        ($x,$y)=($y,$x);
    }
    local $@ = '';
    my $z;
    if ($op =~ /[&|~^][.]=?/) {
        $op =~ s/\.//;
    }
    if ($op eq '-X') {
        $z = eval "-$y \$x";
    } elsif ($op eq 'neg') {
        $z = eval { -$x };
    } elsif ($op eq '!' || $op eq '~' || $op eq '++' || $op eq '--') {
        $z = eval "$op\$x";
    } elsif ($op eq 'qr') {
        $z = eval { qr/$x/ };
    } elsif ($op eq 'atan2') {
        $z = eval { atan2($x,$y) };
    } elsif ($op eq 'cos' || $op eq 'sin' || $op eq 'exp' || $op eq 'abs' ||
             $op eq 'int' || $op eq 'sqrt' || $op eq 'log') {
        $z = eval "$op(\$x)";
    } elsif ($op eq 'bool') {
        $z = eval { $x ? 1 : 0 };  # this isn't right
    } elsif ($op eq '0+') {
        $z = eval "0 + \$x"; # this isn't right, either
    } elsif ($op eq '""') {
        $z = eval { "$x" };
    } elsif ($op eq '<>') {
        # always scalar context readline
        $z = eval { readline($x) };
    } else {  # binary operator
        xdiag("evaluating binary operation '\$x $op \$y' ref=",ref($x));
        $z = eval "\$x $op \$y";
        xdiag("result is \$z=",Data::Dumper::Dumper($z));
    }

    if ($@) {
        xdiag "server: error in overload op: $@";
        return { error => $@ };
    } else {
        xdiag "server: overload result $x $y $op => $z\n"; $DB::single=1;
        return { context => 1, response => $z };
    }
}

sub process_request_HASH {
    my ($self, $obj, $cmd, $has_args, $args) = @_;
    if ($cmd eq 'FETCH') {
	return { context => 1, response => $obj->{$args->[0]} };
    }
    if ($cmd eq 'STORE') {
	my ($key,$val) = @$args;
	$obj->{$key} = $val;
	return { context => 1, response => $val };
    }
    if ($cmd eq 'EXISTS') {
	return {context => 1, response => exists $obj->{$args->[0]}};
    }
    if ($cmd eq 'CLEAR') {
	$obj = {};
	return {context => 0};
    }
    if ($cmd eq 'FIRSTKEY') {
	keys %{$obj};
	my $key = each %{$obj};
	return { context => 1, response => $key };
    }
    if ($cmd eq 'NEXTKEY') {
	my $key = each %{$obj};
	return { context => 1, response => $key };
    }
    if ($cmd eq 'DELETE') {
	return { context => 1, response => delete $obj->{$args->[0]} };
    }
    if ($cmd eq 'SCALAR') {
	return { context => 1, response => scalar %{$obj} };
    }
    die "tied HASH function '$cmd' not recognized";
}

sub process_request_ARRAY {
    my ($self,$obj,$cmd,$has_args,$args,$context) = @_;
    if ($cmd eq 'STORE') {
	my ($index,$val) = @$args;
	return { context => 1, response => ($obj->[$index] = $val) };
    }
    if ($cmd eq 'FETCH') {
	return { context => 1, response => $obj->[$args->[0]] };
    }
    if ($cmd eq 'FETCHSIZE') {
	return { context => 1, response => scalar @{$obj} };
    }
    if ($cmd eq 'STORESIZE') {
	my $n = $#{$obj} = $args->[0] - 1;
	return { context => 1, response => $n + 1 };
    }
    if ($cmd eq 'SPLICE') {
        my ($off,$len,@list) = @$args;
        if ($len eq 'undef') {
            $len = @{$obj} - $off;
        }
        my @val = splice @{$obj}, $off, $len, @list;
        return {context => 2, response => \@val};
    }
    if ($cmd eq 'PUSH') {
        my $n = push @{$obj}, @$args;
        return {context => 1, response => $n };
    }
    if ($cmd eq 'UNSHIFT') {
        my $n = unshift @{$obj}, @$args;
        return {context => 1, response => $n };
    }
    if ($cmd eq 'POP') {
        return {context => 1, response => pop @{$obj} };
    }
    if ($cmd eq 'SHIFT') {
        return {context => 1, response => shift @{$obj} };
    }
    die "tied ARRAY function '$cmd' not recognized";
}

sub process_request_SCALAR {
    my ($self, $obj, $cmd, $has_args, $args) = @_;
    if ($cmd eq 'STORE') {
	${$obj} = $args->[0];
	return { context => 1, response => $$obj };
    }
    if ($cmd eq 'FETCH') {
	return { context => 1, response => ${$obj} };
    }
    die "tied SCALAR function '$cmd' not recognized";
}

sub TEST_MODE {
    $DEFAULT{idle_timeout} = 1;
    $DEFAULT{keep_alive} = 3;
    $DEFAULT{alarm_freq} = 1;
    our $IS_TEST = 1;
}

1;

=head1 NAME

Net::Objwrap::Server - provide server for proxy access to Perl object



=head1 VERSION

0.08



=head1 DESCRIPTION

Remote object server component of L<Net::Objwrap> distribution.
See L<Net::Objwrap> for a description of this module and
instructions for using it.


=head1 FUNCTIONS

=head2 new

=head2 $server = Net::Objwrap::Server->new($file, @objects)

=head2 $server = Net::Objwrap::Server->new(\%opts, $file, @objects)

Creates a new remote object server that initially serves one or
more references in C<@objects>. Writes server connection information
and metadata about the served objects to a file called C<$file>.

If a hash reference is provided as the first argument, it is treated
as a set of server configuration options. Recognized key-value
pairs in server configuration are:

=over 4

=item keep_alive => int

On server startup, keeps the server alive for at least the given
number of seconds, waiting for one or more clients to connect.
Default is 30. In test mode the default is 1.

=item idle_timeout => int

Keeps the server alive for at least the given number of seconds
after the last client has disconnected, to give other clients
time to connect. The default is 30. In test mode, the default is 1.

=item alarm_freq => int

Frequency, in seconds, that the server process accepting new
connections is interrupted. During these interruptions, the server
assesses whether any existing clients have disconnected, and
whether the server will shut down. The server will shut down when
it has been up for at least the number of "keep alive" seconds
(see above), when there are no existing connections from clients,
B<and> when the last interaction with a client was at least
"idle timeout" seconds ago (see above).

=back

=cut

#    
# describe object metadata passed by the server?
# describe the request and response protocols?
#

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2017, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut

