package File::FDpasser;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $OS %ostype);

use Socket;
use IO::Pipe;
use Fcntl; 

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter AutoLoader DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(

	     send_file
	     recv_fd
	     recv_fh
	     serv_accept_fd
	     serv_accept_fh
	     cli_conn
	     spipe
	     endp_create
	     endp_connect
	     my_getfl
	     get_fopen_mode

);

@EXPORT_OK = qw(

);



$VERSION = '0.09';

bootstrap File::FDpasser $VERSION;

BEGIN {
    %ostype=(linux=>'bsd',
	     bsdos=>'bsd',
		 netbsd=>'bsd',
		 openbsd=>'bsd',
	     freebsd=>'bsd',
	     solaris=>'svr',
	     dec_osf=>'bsd',
		 irix=>'bsd',
		 hpux=>'bsd',
		 aix=>'bsd',
	     darwin=>'bsd',
	     );
    
    $OS=$ostype{$^O} || die "Platform $^O not supported!\n";
}

sub spipe {
    local(*RD,*WR);
    if ($OS eq 'bsd') {
	socketpair(RD, WR, AF_UNIX, SOCK_STREAM, PF_UNSPEC) || die "socketpair: $!\n";
    } else {
	pipe(RD,WR) || die "pipe: $!\n";
    }
    return (*RD{IO}, *WR{IO});
}

sub endp_create {
    my($name)=@_;
    my ($sck,$rem);
    if ($OS eq 'bsd') {
	local(*SCK);
	my $uaddr = sockaddr_un($name);
	socket(SCK,PF_UNIX,SOCK_STREAM,0) || return undef;
	unlink($name);
	bind(SCK, $uaddr) || return undef;
	listen(SCK,SOMAXCONN) || return undef;
	$sck=*SCK{IO};
	$sck->autoflush();
    } else {
	local(*SCK,*REM);
	pipe(SCK,REM);
	$sck=*SCK{IO};
	$rem=*REM{IO};
	$sck->autoflush();
	$rem->autoflush();
	unlink($name);
	bind_to_fs(fileno(REM),$name) || return undef;
    }
    return $sck;
}

sub endp_connect {
    local(*FH);
    my($serv)=@_;
    if ($OS eq 'bsd') {
	socket(FH, PF_UNIX, SOCK_STREAM, PF_UNSPEC) || return undef;
	my $sun = sockaddr_un($serv);
	connect(FH,$sun) || return undef;
    } else {
	open(FH,$serv) || return undef;
	if (!my_isastream(fileno(FH))) { close(FH); return undef; }
    }
    return *FH{IO};
}

sub recv_fd {
    my ($conn)=@_;
    if (ref($conn) =~ m/^IO::/) { $conn=fileno($conn); }
#    print "recv_fd: ",$conn,"\n";
    my $fd=my_recv_fd($conn);
#    print "recv_fd: $!\n";
    if ($fd <0) { return undef; }
    return $fd;
}

sub recv_fh {
    my ($conn)=@_;
    if (ref($conn) =~ m/^IO::/) { $conn=fileno($conn); }
#    print "recv_fh conn: $conn\n";
    my ($fd)=my_recv_fd($conn);
#    print "recv_fh fd: $fd\n";
    if ($fd <0) { return undef; }
    my $fh=IO::Handle->new();
    $fh->fdopen($fd,get_fopen_mode($fd)) || return undef;
    return $fh;
}

sub send_file {
    my($conn,$sendfd)=@_;
    my $fd_rc;
    if (ref($conn) =~ m/^IO::/) { $conn=fileno($conn); }
    if (ref($sendfd) =~ m/^IO::/) { $sendfd=fileno($sendfd); }
    if ($conn !~ /^\d+$/ or $sendfd !~ /^\d+$/) { die "Invalid args to send_file: $_[0], $_[1]\n"; }
#    print "send_file: $conn, $sendfd\n";
    $fd_rc=my_send_fd($conn,$sendfd) && return undef;
    return 1;
}

sub serv_accept_fd {
    my($lfd,$uid)=@_;
    if (ref($lfd) =~ m/^IO::/) { $lfd=fileno($lfd); } else { return undef; }
    my $fd=my_serv_accept($lfd,$uid);
#    print "retfd: $fd\n";
    if ($fd<0) { return undef; }
    return $fd;
}

sub serv_accept_fh {
    my($LFH,$uid)=@_;
    local(*FH);
    my $lfd;
    if (ref($LFH) =~ m/^IO::/) { $lfd=fileno($LFH); } else { return undef; }
    if ($OS eq 'bsd') { 
	accept(FH,$LFH) || return undef;
	return *FH{IO};
    } else {
	my $fd=my_serv_accept($lfd,$uid);
	if ($fd <0) { return undef; }
	my $fh=IO::Handle->new();
	$fh->fdopen($fd,get_fopen_mode($fd)) || return undef;
	return $fh;
    }
}

sub get_fopen_mode {
    my $fd=$_[0];

    my $rc=my_getfl($fd);
#    print "fd: $rc\n";
    return undef if $rc <0;
    my $acc=($rc&(O_WRONLY|O_RDONLY|O_RDWR));
    my $app=($rc&O_APPEND);
    if ($acc == O_RDONLY) { return "r"; }
    if ($acc == O_WRONLY and !$app)  { return "w"; }
    if ($acc == O_WRONLY and $app) { return "a"; }
    if ($acc == O_RDWR and !$app) { return "w+"; }
    if ($acc == O_RDWR and $app) { return "a+"; }
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

File::FDpasser - Perl extension for blah blah blah

=head1 SYNOPSIS

	use File::FDpasser;

	@fd=spipe();
	die "spipe() failed\n" if !defined(@fd);

	$LS=endp_create("/tmp/openserver") || die "endp_create: $!\n";

	$rin = ''; vec($rin,fileno($LS),1) = 1; $timeout=0.5;
	($nfound,$timeleft) = select($rout=$rin, '', $eout=$rin, $timeout);

	$fh=serv_accept_fh($LS,$uid) || die "serv_accept: $!\n";
	$rc=send_file($fh,*FH{IO});
 
	$fh=endp_connect("/tmp/openserver") || die "endp_connect: $!\n";
	$newfh=recv_fh($fh);

=head1 DESCRIPTION

File::FDpasser is a module for passing open filedescriptors 
to and from other scripts or even other programs.

An endpoint is just a Filehandle that can be used to 
send and receive filehandles over.  To create two endpoints
before forking spipe() is used - it returns two endpoints
or undef on failiure.  

If the processes are unrelated or can not use spipe() for
some reason, it is possible to create a 'server endpoint'
in the filesystem by calling endp_create().  That endpoint
can be polled for incomming connections similar to how sockets
are polled for incomming connection.  To accept an incomming
connection serv_accept_fh() is used. It returns a filehandle
or undef on failiure.

To connect to a server endpoint from a client program
endp_connect() is used. It returns a filehandle to an 
open connection.

Irregardless of how the endpoints were created send_file()
is used to send an open filehandle to the process who has
other end of the pipe or socket.  The first argument to 
send_file is the connection to send the open handle over.
The second argument is the actual handle to send. 
Similarly recv_fh() is always used to receive an open
filehandle.  Both return false on failiure.

=head1 How does it work

Under BSD derived systems open filedescriptors are passed over
unix domain sockets.  SysV systems however pass them over streams.

This means to create that under BSD socketpair() is used to
create the socket endpoints.  While SysV uses pipe() since 
pipe on SysV creates a bidirectional stream based pipe.

This is all nice and dandy if you are going to fork later on
since both child and parent are going to have an endpoint to
read from or write to.  

endp_create() is used to create a server endpoint that can
be polled for incomming connections with poll or select.
Under BSD the perl call socket() is used to create a Unix Domain
Socket in the filesystem.  Under SysV the perl function pipe()
is called followed by an XS function that pushes the conn_ld module
on one end of the stream pipe and then calles fattach to attach 
the pipe end to a point in the filesystem.

To connect to a server endpoint in BSD a socket is created (but not
bound to any point in the filesystem) and a connect call is made.
In SysV a normal open() in perl is made.

The actuall sending of filedescriptors is done with XS functions
that under BSD use sendmsg for sending and recvmsg for reciving.
SysV uses an ioctl call to send and receive (getmsg is actually 
a wrapper for receiving the fd - a uid of the connecting process is
discarded since it's not reliably avaliable for BSD system too).

=head1 AUTHOR

addi@umich.edu

=head1 SEE ALSO

perl(1), sendmsg, recvmsg, ioctl, ioctl_list, select, poll.
IO::Handle.
http://www.eecs.umich.edu/~addi/perl/FDpasser/.
Advanced Programming in the UNIX Environment, Addison-Wesley, 1992.
UNIX Network Programming, Prentice Hall, 1990.

=cut
