package GPIB::rmt;

use strict;
use MD5;
use IO::Socket;
use Storable qw(nstore_fd retrieve_fd);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $defaultPort $AUTOLOAD);

@ISA = qw( );
@EXPORT = qw( );
$VERSION = '0.30';

$defaultPort = 90;

# The first time a given method is called in GPIB::rmt, AUTOLOAD makes
# a closure to do network access for the method.  The inefficiency
# of going through autoload only happens once on the first call
# for each method.  This is actually amazingly efficient since there
# is just one piece of code shared by all of the methods, the 
# difference being the $name parameter bound when the closure is
# formed.
sub AUTOLOAD {
    return if $AUTOLOAD =~ /DESTROY/;
    {   no strict 'refs';
        my $name;
        ($name = $AUTOLOAD) =~ s/.*:://;
        *$AUTOLOAD = sub { 
            my $g=shift; 
            my  $resp;

            unshift @_, $name;
            eval {  nstore_fd(\@_, $$g{socket}); $$g{socket}->flush; };
            die "Network connection broken." if $@;

            eval { $resp = retrieve_fd($$g{socket}); };
            die "Network connection broken." if $@;
            $$g{ibsta} = $resp->[1];
            $$g{iberr} = $resp->[2];
            $$g{ibcnt} = $resp->[3];
            # close $$g{socket} if $name eq "close";
            return $resp->[0];
        };
    }
    goto &$AUTOLOAD;
}

sub DESTROY {
    my $g = shift;
    close $$g{socket};
}

# Access to ibsta, iberr, and ibcnt don't go over the network, they
# are returned by all of the calls that affect them and stored
# on the client machine for more efficient access.
sub ibsta { return ${$_[0]}{ibsta}; }
sub iberr { return ${$_[0]}{iberr}; }
sub ibcnt { return ${$_[0]}{ibcnt}; }

sub new {
    my  $pkg       = shift;
    my  $host      = shift;
    my  $user      = shift;
    my  $password  = shift;
    my  $g = {};
    my  $port = $defaultPort;
    my  $resp;
    my  ($s_name, $s_version, $s_rand, $hash, $md5);

    # Open socket to server on remote machine
    ($host, $port) = split/:/, $host if $host =~ /:/;
    $$g{socket} = IO::Socket::INET->new(PeerAddr => $host,
                        PeerPort => $port, Proto    => 'tcp');
    die "Cannot open connection to server $host:$port\n    " unless $$g{socket};

    # First line from host contains Server type, version, and a random number
    ($resp = $$g{socket}->getline) =~ s/[\r\n]//g;
    ($s_name, $s_version, $s_rand) = split / /, $resp, 3;
    die "Unnown server: $s_name\n    " if $s_name ne "GPIBProxy";
    if (int($VERSION) != int($s_version)) {
        die "Client: $VERSION, Server: $s_version version mismatch\n    ";
    }

    # Make an MD5 hash of randon number and password for server
    # This way each connection does a different exchange and the password
    # is never sent in the clear.
    $md5 = new MD5;
    $md5->reset;
    $md5->add($password, $s_rand);
    $hash = $md5->hexdigest;

    # Send client version, user name, and hashed password to server
    $$g{socket}->print("$VERSION $user $hash\n");
    ($resp = $$g{socket}->getline) =~ s/[\r\n]//g;
    die "Network connection lost in authentication\n    " if $@;
    die "Server: $resp\n    " if $resp =~ s/^NO //;
    die "Unexpected authentication response: $resp\n    " if !($resp=~ /^OKAY/);

    # Stash away interesting information about the connection
    $$g{server_version} = $s_version;
    $$g{server_name} = $host;
    $$g{server_port} = $port;
    $$g{user_name} = $user;
    $$g{new} = \@_;

    # Send parameters for new() method on remote server
    # Get back result of new()
    # die if server has an error on the new()
    eval {
        nstore_fd(\@_, $$g{socket}); $$g{socket}->flush;
        $resp = retrieve_fd($$g{socket});
    };
    die "Network connection broken." if $@;
    $$g{ibsta} = 0;
    $$g{iberr} = 0;
    $$g{ibcnt} = 0;
    die "Remote error for GPIB->new(@_) at $host:$port
             Error was $resp->[1]\n" if $resp->[0] eq "NO";

    bless $g, $pkg;
    return $g;
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

GPIB::rmt - Perl-GPIB interface for GPIB access on a remote host

=head1 SYNOPSIS

  use GPIB::rmt;

=head1 DESCRIPTION

GPIB::rmt is an interface module for making a network connection
to a remote server machine and executing GPIB commands.  This module 
is not normally called directly, but is called by the GPIB.pm module 
according to an entry in /etc/pgpib.conf.

The design goal is that an application program can access GPIB
devices on a remote server identically to local devices, the only 
difference being the configuration in /etc/pgpib.conf.  This module 
has been tested on both Linux and NT4.0.  The Perl script that acts 
as the server on the remote machine is pretty Unix oriented, but it 
can probably be ported to NT without too much difficulty.  This client
code runs equally well on NT and Linux.

The author's typical usage is to use a Linux machine with an NI
GPIB card as a server for a collection of test equipment.  The Linux
machine runs a server program and listens for requests from clients.
The clients are a collection of NT4.0 and Linux machines that use 
GPIB::rmt to access the GPIB devices.

A /etc/pgpib.conf entry for a GPIB::rmt device is as follows:

  # name     interface  Host             user   password  remote name
  HP3585A    GPIB::rmt  sparky.mock.com  jeff   fiddle    HP3585A

The name field is the identifier used on the local machine for accessing
the device.  The host can be a domain name as shown above, an IP 
address, or include a port number in form foo.bar:90.  The module
uses port 90 by default.

The remote name parameter is the name of the /etc/pgpib.conf entry 
on the remote server machine.  Typically the local name and remote name
will be the same.

Once configured in /etc/pgpib.conf, the module is used the same
as any other GPIB module:

  use GPIB;

  $g = GPIB->new("HP3585A");
  $g->ibwrt("Command to remote machine");

=head1 SECURITY

The server keeps a list of user names and passwords.  The password
is never sent as clear text over the network, it is hashed with a 
random number using MD5.  Just the same, the username and passwords
are kept as clear text on each machine and this authentication is probably 
no better than the tiny lock on the top drawer of your desk.  

I do not recommend exposing the server to the Internet.  It's great
for access within a local network, but should not be considered 
secure in unfriendly environments.

=head1 SERVER

The sever is included in the distribution as a Perl script called
pgpibproxy.  This is a very simple script designed to run as a daemon
on a Linux machine.  The script keeps a list of users and passwords
in the file /etc/pgpibusers.  Because of the system and security issues
the server is not installed by default.  

You should look at the script, change any parameters for the local
configuration and install the script someplace where you keep 
important system files.  I put it in /etc.  I start the script up
automatically from /etc/rc.d/rc.local.  It runs as a daemon.
Before starting the script you need to setup a list of users.  You
can live on the edge and set $passwordcheck to 0 in the server
and no authentication is done, but that's probably not wise.  You
need to make a file called /etc/pgpibusers that has one user per
line, a username followed by a password separated by white space.
Once you have created the password file and modified the server for
you can start up the server.  If you change the password file you
do not need to restart the server, it will re-read pgpibusers.

The script listens for connections and forks a process when it 
gets a connection from a client machine.  If the client machine
authenticates correctly then GPIB calls made on the client machine
are translated into GPIB calls on the server.  The server and
client use the MD5 module to hash the password and the Storable
module to pack Perl data structures for transmission across the network.

Again, I suggest you make sure that the server is not directly accessable 
from the Internet.

=head1 AUTHOR

Jeff Mock, jeff@mock.com

=head1 SEE ALSO

perl(1), GPIB(3), GPIB::ni(3), GPIB::hpserial(3).

=cut


