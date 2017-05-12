package Farly::ASA::PortFormatter;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.26';

our $String_To_Int = {
    "aol"               => 5190,
    "bgp"               => 179,
    "biff"              => 512,
    "bootpc"            => 68,
    "bootps"            => 67,
    "chargen"           => 19,
    "cifs"              => 3020,
    "citrix-ica"        => 1494,
    "ctiqbe"            => 2748,
    "daytime"           => 13,
    "discard"           => 9,
    "dnsix"             => 195,
    "domain"            => 53,
    "echo"              => 7,
    "exec"              => 512,
    "finger"            => 79,
    "ftp"               => 21,
    "ftp-data"          => 20,
    "gopher"            => 70,
    "h323"              => 1720,
    "hostname"          => 101,
    "https"             => 443,
    "ident"             => 113,
    "imap4"             => 143,
    "irc"               => 194,
    "isakmp"            => 500,
    "kerberos"          => 750,
    "klogin"            => 543,
    "kshell"            => 544,
    "ldap"              => 389,
    "ldaps"             => 636,
    "login"             => 513,
    "lotusnotes"        => 1352,
    "lpd"               => 515,
    "mobile-ip"         => 434,
    "nameserver"        => 42,
    "netbios-dgm"       => 138,
    "netbios-ns"        => 137,
    "netbios-ssn"       => 139,
    "nfs"               => 2049,
    "nntp"              => 119,
    "ntp"               => 123,
    "pcanywhere-data"   => 5631,
    "pcanywhere-status" => 5632,
    "pim-auto-rp"       => 496,
    "pop2"              => 109,
    "pop3"              => 110,
    "pptp"              => 1723,
    "radius"            => 1645,
    "radius-acct"       => 1646,
    "rip"               => 520,
    "rsh"               => 514,
    "rtsp"              => 554,
    "secureid-udp"      => 5510,
    "sip"               => 5060,
    "sip"               => 5060,
    "smtp"              => 25,
    "snmp"              => 161,
    "snmptrap"          => 162,
    "sqlnet"            => 1521,
    "ssh"               => 22,
    "sunrpc"            => 111,
    "syslog"            => 514,
    "tacacs"            => 49,
    "talk"              => 517,
    "telnet"            => 23,
    "tftp"              => 69,
    "time"              => 37,
    "uucp"              => 540,
    "who"               => 513,
    "whois"             => 43,
    "www"               => 80,
    "xdmcp"             => 177,
};

our $Int_To_String = { reverse %$String_To_Int };

sub new {
    return bless {}, $_[0];
}

sub as_string {
    return $Int_To_String->{ $_[1] };
}

sub as_integer {
    return $String_To_Int->{ $_[1] };
}

1;
__END__

=head1 NAME

Farly::ASA::PortFormatter - Maps port string ID's and integers

=head1 DESCRIPTION

Farly::ASA::PortFormatter is like an enum class, but not.
PortFormatter is device specific.

=head1 METHODS

=head2 new()

The constructor.

=head2 as_string( <port number> )

Returns a port name for the given port number.

=head2 as_integer( <protocol ID> )

Returns a port number for the given port name.

=head1 COPYRIGHT AND LICENCE

Farly::ASA::PortFormatter
Copyright (C) 2012  Trystan Johnson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
