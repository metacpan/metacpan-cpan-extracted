package Enbugger::ebug;
$Enbugger::ebug::VERSION = '2.016';
# COPYRIGHT AND LICENCE
#
# Copyright (C) 2007,2008 WhitePages.com, Inc. with primary
# development by Joshua ben Jore.
#
# This program is distributed WITHOUT ANY WARRANTY, including but not
# limited to the implied warranties of merchantability or fitness for
# a particular purpose.
#
# The program is free software.  You may distribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation (either version 2 or any later version)
# and the Perl Artistic License as published by O’Reilly Media, Inc.
# Please open the files named gpl-2.0.txt and Artistic for a copy of
# these licenses.

=head1 NAME

Enbugger:ebug - subclass for the Devel::ebug debugger

=head1 DESCRIPTION

This ought to be a hook into the Devel::ebug::Backend debugger. I
don't immediately know how to hook it up properly.

=cut

use vars qw( @ISA @Symbols );
BEGIN { @ISA = 'Enbugger' }

sub _load_debugger {
    my ( $class ) = @_;
    
    $class->_compile_with_nextstate();
    require Devel::ebug::Backend;
    $class->_compile_with_dbstate();
    
    $class->init_debugger;
    
    return;
}

1 if $DB::signal;
sub _stop {

    # perl5db looks for this to stop.
    $DB::signal = 1;

    # Use at least the default debug flags.
    $^P |= 0x33f;

    return;
}

# sub _write {
# }

# Load up a list of symbols known to be associated with this
# debugger. Enbugger, the base class will use this to guess at which
# debugger has been loaded if it was loaded prior to Enbugger being
# around.
while ( my $line = <DATA> ) {
    $line =~ s/[\r\n]+\z//;

    # Stop reading once I hit the paragraph of at the end.
    last if not $line;

    push @{$Enbugger::RegisteredDebuggers{ebug}{symbols}}, $line;
}
close *DATA;



() = -.0

__DATA__
AF_802
AF_AAL
AF_APPLETALK
AF_CCITT
AF_CHAOS
AF_CTF
AF_DATAKIT
AF_DECnet
AF_DLI
AF_ECMA
AF_GOSIP
AF_HYLINK
AF_IMPLINK
AF_INET
AF_INET6
AF_ISO
AF_KEY
AF_LAST
AF_LAT
AF_LINK
AF_MAX
AF_NBS
AF_NIT
AF_NS
AF_OSI
AF_OSINET
AF_PUP
AF_ROUTE
AF_SNA
AF_UNIX
AF_UNSPEC
AF_USER
AF_WAN
AF_X25
BEGIN
DB
Dump
DumpFile
END
INADDR_ANY
INADDR_BROADCAST
INADDR_LOOPBACK
INADDR_NONE
IOV_MAX
IP_HDRINCL
IP_OPTIONS
IP_RECVOPTS
IP_RECVRETOPTS
IP_RETOPTS
IP_TOS
IP_TTL
Load
LoadFile
MSG_BCAST
MSG_BTAG
MSG_CTLFLAGS
MSG_CTLIGNORE
MSG_CTRUNC
MSG_DONTROUTE
MSG_DONTWAIT
MSG_EOF
MSG_EOR
MSG_ERRQUEUE
MSG_ETAG
MSG_FIN
MSG_MAXIOVLEN
MSG_MCAST
MSG_NOSIGNAL
MSG_OOB
MSG_PEEK
MSG_PROXY
MSG_RST
MSG_SYN
MSG_TRUNC
MSG_URG
MSG_WAITALL
MSG_WIRE
PF_802
PF_AAL
PF_APPLETALK
PF_CCITT
PF_CHAOS
PF_CTF
PF_DATAKIT
PF_DECnet
PF_DLI
PF_ECMA
PF_GOSIP
PF_HYLINK
PF_IMPLINK
PF_INET
PF_INET6
PF_ISO
PF_KEY
PF_LAST
PF_LAT
PF_LINK
PF_MAX
PF_NBS
PF_NIT
PF_NS
PF_OSI
PF_OSINET
PF_PUP
PF_ROUTE
PF_SNA
PF_UNIX
PF_UNSPEC
PF_USER
PF_WAN
PF_X25
SCM_CONNECT
SCM_CREDENTIALS
SCM_CREDS
SCM_RIGHTS
SCM_TIMESTAMP
SHUT_RD
SHUT_RDWR
SHUT_WR
SOCK_DGRAM
SOCK_RAW
SOCK_RDM
SOCK_SEQPACKET
SOCK_STREAM
SOL_SOCKET
SOMAXCONN
SO_ACCEPTCONN
SO_ATTACH_FILTER
SO_BACKLOG
SO_BROADCAST
SO_CHAMELEON
SO_DEBUG
SO_DETACH_FILTER
SO_DGRAM_ERRIND
SO_DONTLINGER
SO_DONTROUTE
SO_ERROR
SO_FAMILY
SO_KEEPALIVE
SO_LINGER
SO_OOBINLINE
SO_PASSCRED
SO_PASSIFNAME
SO_PEERCRED
SO_PROTOCOL
SO_PROTOTYPE
SO_RCVBUF
SO_RCVLOWAT
SO_RCVTIMEO
SO_REUSEADDR
SO_REUSEPORT
SO_SECURITY_AUTHENTICATION
SO_SECURITY_ENCRYPTION_NETWORK
SO_SECURITY_ENCRYPTION_TRANSPORT
SO_SNDBUF
SO_SNDLOWAT
SO_FAMILY
SO_KEEPALIVE
SO_LINGER
SO_OOBINLINE
SO_PASSCRED
SO_PASSIFNAME
SO_PEERCRED
SO_PROTOCOL
SO_PROTOTYPE
SO_RCVBUF
SO_RCVLOWAT
SO_RCVTIMEO
SO_REUSEADDR
SO_REUSEPORT
SO_SECURITY_AUTHENTICATION
SO_SECURITY_ENCRYPTION_NETWORK
SO_SECURITY_ENCRYPTION_TRANSPORT
SO_SNDBUF
SO_SNDLOWAT
SO_SNDTIMEO
SO_STATE
SO_TYPE
SO_USELOOPBACK
SO_XOPEN
SO_XSE
UIO_MAXIOV
VERSION
__ANON__
args
break_point_condition
dbline
except
fake::
fetch_codelines
get
inet_aton
inet_ntoa
initialise
only
pack_sockaddr_in
pack_sockaddr_un
plugins
put
search_path
signal
single
sockaddr_family
sockaddr_in
sockaddr_un
sub
unpack_sockaddr_in
unpack_sockaddr_un

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:
