package Ingres::Utility::Netutil;

use warnings;
use strict;
use Carp;
use Expect::Simple;

=head1 NAME

Ingres::Utility::Netutil - API to C<netutil> Ingres RDBMS utility


=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Ingres::Utility::Netutil;
    
    # create a connection to NETUTIL utility
    
    $netu = Ingres::Utility::Netutil->new();
    
    # Attention: many arguments accept wildcard *
    
    # showLogin($type,$vnode) - prepare to provide info on login VNodes
    #                           and return netutil ouput
    print $netu->showLogin('global','*');
    
    #
    # getLogin() - return one-by-one all login VNodes previously prepared
    while ( ($type, $login, $vnode, $acct) = $netu->getLogin() ) {
    	print "Type: $type\tName: $vnode\tAccount: $acct\n";
    }
    
    # showConn($type, $conn, $vnode, $addr, $proto, $listen)
    #                         - prepare to provide info on connections of a VNode
    #                           and return netutil ouput
    print $netu->showConn('global','sample_vnode_name', '*', '*', '*');
    
    #
    # getConn() - return one-by-one all connections of a VNodes previously prepared
    while ( @conn = $netu->getConn() ) {
	($type, $conn, $vnode, $addr, $proto, $listen) = @conn;
    	print "Type: $type\tName: $vnode\tAddress: $addr\tProtocol: $proto";
    	print "\tListen Address: $listenAddr\n";
    }
    
    # createLogin($type,$vnode,$acct, $passwd) - create a new VNode
    $netu->createLogin('global', 'new_vnode_name', 'sample_login_account', 'secret_passwd');
    
    # createConn($type,$vnode,$addr,$proto,$listenAddr) - create a connection for a VNode
    $netu->createConn('global', 'new_vnode_name', '192.168.0.1', 'tcp_ip', 'II');
    
    # destroyConn($type,$vnode,$acct, $passwd) - destroy a connection from a VNode
    $netu->destroyConn('global', 'new_vnode_name', '192.168.0.1', 'tcp_ip', 'II');
    
    # destroyLogin($type,$vnode) - destroy a VNode and all connections
    $netu->destroyLogin('global', 'new_vnode_name');
    
    # quiesceServer($serverId) - stop IIGCC server after all connections close (die gracefully)
    # if no $serverId is given, then all IIGCC servers are affected (carefull).
    $netu->quiesceServer('sample_server_id');
    
    # stopServer($serverId) - stop IIGCC server imediately (break connections)
    # if no $serverId is given, then all IIGCC servers are affected (carefull).
    $netu->stopServer('sample_server_id');

The server id can be obtained through L<Ingres::Utility::IINamu> module.
  
  
=head1 DESCRIPTION

This module provides an API to netutil utility for Ingres RDBMS,
which provides local control of IIGCC servers for Ingres Net
inbound and outbound remote connections, and also manage logins
and connections to remote servers, a.k.a. VNodes.

=over

Notes:

Ordinary user can create/destroy on his own private logins and connections.

SECURITY privilege should be granted to have access to other user's private
entries.

GCA privilege NET_ADMIN (generally a system administrator) needed to manage
global type login and connection entries.

GCA privilege SERVER_CONTROL (generally a system administrator) needed to stop
a communications server.

=back

=head1 METHODS

=over

=item new(;('USER' => $user, 'VNODE' => $vnode})

Start interaction with netutil utility.

Takes an optional hash with the user id and remote vnode arguments to
identify which user's private VNodes to control and which remote's
machine Net configuration to manage. The VNode must be previously created.

=cut

sub new(;%) {
	my $class = shift;
	my $this = {};
	$class = ref($class) || $class;
	bless $this, $class;
    my %params;
    if (@_) {
        (%params) = @_;
    }
    my $userId;
    $userId = (exists $params{'USER'} ? $params{'USER'} : ''); 
    $userId = (exists $params{'user'} ? $params{'user'} : $userId); 
	my $vnode;
    $vnode  = (exists $params{'VNODE'} ? $params{'VNODE'} : '');
    $vnode  = (exists $params{'vnode'} ? $params{'vnode'} : $vnode);
	if (! defined($ENV{'II_SYSTEM'})) {
		carp "Ingres environment variable II_SYSTEM not set";
        return undef;
	}
	my $Netutil_file = $ENV{'II_SYSTEM'} . '/ingres/bin/netutil';
	if (! -x $Netutil_file) {
		carp "Ingres utility cannot be executed: $Netutil_file";
        return undef;
	}
    my @cmdParams = ('-file-');
	if ($userId) {
		push @cmdParams, "-u $userId";
	}
	if ($vnode) {
		push @cmdParams, "-vnode $vnode";
	}
    # $Netutil_file .= ' ' . join(' ',@cmdParams); Expect->spawn signature not equal Expect::Simple->new
	$this->{cmd} = $Netutil_file;
#    $this->{cmd} .= join(' ',@cmdParams);
    $this->{cmdInject} = "_C_M_D_I_N_J_E_C_T_"; # injects a command do to induce "fake prompt"
    $this->{prompt} = ['-re', "\\[.+\\].+" . $this->{cmdInject} . ".*\$"];  # error message in fact due to cmdInject
#    $this->{cmdInject} = '';
#    $this->{prompt} = ['-re', "^NETUTIL>"];
	$this->{xpct} = new Expect
                    or do {
                        carp "Module Expect cannot be instanciated";
                        return undef;
                    };
    my $obj = $this->{xpct};
    $obj->debug(0);
    $obj->exp_internal(0);
    $obj->log_stdout(0);
    $obj->spawn($Netutil_file, @cmdParams)
        or do {
            carp "Module Expect cannot be instanciated";
            return undef;
        };
    $obj->log_stdout(0); # just to be shure!
    $obj->restart_timeout_upon_receive(1);
    #$obj->send("\n");
    $obj->expect(1, '-re', '^.+$'); # gets first prompt
    $obj->clear_accum(); # and wipe it
    $this->{userId}    = $userId;
    $this->{vnode}     = $vnode;
    $this->{cmdParams} = \@cmdParams;
    $this->{timeout}   = 2;
	return $this;
}


=item debug($debug_level)

Activate Expect Module debuging.

=cut

sub debug( $$ ) {
    my $this = shift;
	my $obj  = $this->{xpct};
    if ($obj and @_) {
        $obj->debug(shift);
        $obj->exp_internal(1);
    }
}
# Do the real interactions with netutil utility
sub _send() {
	my $this = shift;
	my $obj  = $this->{xpct};
    my @cmd = @_;
    if ($this->{cmdInject}) {
        push @cmd, $this->{cmdInject};
    }
    for (my $i =0; $i < (scalar @cmd); $i++) {
        $cmd[$i] .= "\n";
    }
    $obj->clear_accum();
	$obj->send(@cmd);
    $obj->expect($this->{timeout}, @{$this->{prompt}})
        or do {
            carp "Cannot Expect::expect(): " . $obj->error();
            return undef;
        };
}

# Filter double spaces, removes the input echo, injected command and return an
# array of output lines
sub _getCleanArray($$$$ ) {
    my $this = shift;
    return undef if ( (scalar @_) != 3);
    my ($cmd, $cmdInject, $before) = @_;
	while ($before =~ /\ \ /) {
		$before =~ s/\ \ /\ /g;
	}
	my @lines  = split /\r\n/,$before;
    if (defined $lines[0]) {
        if ($lines[0] eq $cmd) {
            shift @lines;
        }
        if (defined $lines[0] and $cmdInject) { # removes injected command
            if ($lines[0] eq $cmdInject) {
                shift @lines;
            }
        }
    }
    return @lines;
}

# Return line after line of the {stream} array in a sequential access
# each line is parsed into an array of words
sub _getLineArray($$ ) {
	my $this = shift;
    my $object = uc (@_ ? shift : '');
    my $caller;
    if ($object eq 'LOGIN') {
        $caller = 'Login';
    }
    elsif ($object eq 'CONNECTION') {
        $caller = 'Conn';
    }
    else {
        carp "internal error in _getLineArray(): wrong parameter";
        return undef;
    }
	if ($this->{streamType} ne $object) {
		carp "show" . $caller . "() must be previously invoked";
        return undef;
	}
	if (! $this->{stream}) {
		return ();
	}
	if (! $this->{streamPtr}) {
		$this->{streamPtr} = 0;
	}
	my @antes = @{$this->{stream}};
	if ((scalar @antes) <= $this->{streamPtr}) {
		$this->{streamPtr} = 0;
		return ();
	}
	my $line    = $antes[$this->{streamPtr}++];
	my @linearr = split /\ /, $line;
    return @linearr;
}

=item showLogin(;$type, $vnode)

Prepare to return VNode login info.

Returns output from netutil.

Takes the VNode type to filter and name

 $type      - VNode type: GLOBAL/PRIVATE (no wildcard)
 $vnode     - VNode/*

=cut

sub showLogin ($;$){
	my $this = shift;
	my $type = uc (@_ ? shift : '*');
	if ($type) {
		if ($type ne 'GLOBAL'  &&
		    $type ne 'PRIVATE') {
				carp "invalid type: $type";
                return undef;
		}
	}
	my $vnode   = uc (@_ ? shift : '*');
	$this->{streamType} = 'LOGIN';
	my $cmd     = "SHOW $type ". $this->{streamType} . " $vnode";
    $this->_send($cmd);
	my $obj     = $this->{xpct};
	my $before  = $obj->before();
	my @lines   = $this->_getCleanArray($cmd,$this->{cmdInject},$before);
    
    $this->{stream}     = \@lines;
	$this->{streamPtr}  = 0;
	$this->{streamType} = 'LOGIN';
	return join("\n",@lines);
}


=item getLogin()

Returns sequentially (call-after-call) each VNode info reported by showLogin() as an array of
4 elements:
    @login = getlogin();
    # $login[0] = VNode type (GLOBAL/PRIVATE)
    # $login[1] = 'LOGIN'
    # $login[2] = VNode
    # $login[3] = User/*

Password is not returned.

=cut

sub getLogin() {
	my $this = shift;
    return $this->_getLineArray('LOGIN');
}


=item showConn($type; $vnode, $addr, $proto, $listen)

Prepare to return VNode connection info.

Returns output from netutil.

Takes the following parameters:
    $type    - VNode type: GLOBAL/PRIVATE (no wildcard)
    $vnode   - VNode/*
    $addr    - IP, hostname of the server/*
    $proto   - protocol name (tcp_ip, win_tcp, ipx, etc.)/*
    $listen  - remote server's listen address (generaly 'II')/*

=cut

sub showConn {
	my $this = shift;
	my $type = uc (@_ ? shift : '*');
	if ($type) {
		if ($type ne 'GLOBAL'  &&
		    $type ne 'PRIVATE') {
				carp "invalid type: $type";
                return undef;
		}
	}
	my $vnode  = uc (@_ ? shift : '*');
	my $addr   = uc (@_ ? shift : '*');
	my $proto  = uc (@_ ? shift : '*');
	my $listen = uc (@_ ? shift : '*');
	$this->{streamType} = 'CONNECTION';
    my $cmd    = "SHOW $type " . $this->{streamType} . " $vnode $addr $proto $listen";
	$this->_send($cmd);
	my $obj    = $this->{xpct};
	my $before = $obj->before();
	my @lines  = $this->_getCleanArray($cmd,$this->{cmdInject},$before);
    $this->{stream}     = \@lines;
	$this->{streamPtr}  = 0;
	return join("\n",@lines);
}


=item getConn()

Returns sequentially (call-after-call) each VNode connection info reported by showConn() as an array of
6 elements:
    @conn = getConn();
    # $conn[0] = VNode type (GLOBAL/PRIVATE)
    # $conn[1] = 'CONNECTION'
    # $conn[2] = VNode
    # $conn[3] = Network address
    # $conn[4] = Protocol
    # $conn[5] = Listen address

=cut

sub getConn() {
	my $this = shift;
    return $this->_getLineArray('CONNECTION');
}


=item createLogin($type, $vnode, $user, $passwd)

Create a Login VNode.
    
Returns output from netutil.

Takes the following parameters:
    $type   - VNode type: GLOBAL/PRIVATE
    $vnode  - VNode name
    $user   - User account/*
    $passwd - User/installation password

The Installation Password can be created invoking this method as follows:

    $netu = Ingres::Utility::Netutil->new();
    
    my $local_vnode = 'myhost.mydomain'; # See note below about $local_vnode
    
    $netu->createLogin('GLOBAL', $local_vnode, '*', $installation_passwd);

Note: The virtual node name must be identical to the name that has been
configured as LOCAL_VNODE on the Configure Name Server screen of the
cbf utility. No connection needed

=cut

sub createLogin($$$$) {
	my $this = shift;
	my $type = uc (@_ ? shift : '*');
	if ($type ne 'GLOBAL'  &&
	    $type ne 'PRIVATE') {
			carp "invalid type: $type";
            return undef;
	}
	my $vnode = uc (@_ ? shift : '');
	if (! $vnode) {
		carp "missing VNode name";
        return undef;
	}
	my $user = @_ ? shift : '';
	if (! $user) {
		carp "missing User account or '*'";
        return undef;
	}
	my $passwd = @_ ? shift : '';
	if (! $passwd) {
		carp "missing password";
        return undef;
	}
    #my $before = $this->destroyLogin($type, $vnode);
	my $cmd    = "CREATE $type LOGIN $vnode $user $passwd";
    $passwd    = undef; # get rid of passwd
    $this->_send($cmd);
	my $obj    = $this->{xpct};
	my $before = $obj->before();
	my @lines  = $this->_getCleanArray($cmd,$this->{cmdInject},$before);
    $cmd       = undef; # get rid of passwd
	$this->{stream}     = {};	# no more getLogin()/getConn()
	$this->{streamPtr}  = 0;
	$this->{streamType} = '';
	return join("\n",@lines);
}


=item createConn($type, $vnode, $add, $proto, $listen)

Create a connection for a Login VNode previously created.

Returns output from netutil.

Takes the following parameters:
    $type    - VNode type: GLOBAL/PRIVATE
    $vnode   - VNode name
    $addr    - IP, hostname of the server
    $proto   - protocol name (tcp_ip, win_tcp, ipx, etc.)
    $listen  - remote server's listen address (generaly 'II')

=cut

sub createConn($$$$$) {
	my $this = shift;
	my $type = uc (@_ ? shift : '*');
	if ($type ne 'GLOBAL'  &&
	    $type ne 'PRIVATE') {
			carp "invalid type: $type";
            return undef;
	}
	my $vnode = uc (@_ ? shift : '');
	if (! $vnode) {
		carp "missing VNode name";
        return undef;
	}
	my $addr = uc (@_ ? shift : '');
	if (! $addr) {
		carp "missing network address";
        return undef;
	}
	my $proto = @_ ? shift : '';
	if (! $proto) {
		carp "missing network protocol";
        return undef;
	}
	my $listen = uc(@_ ? shift : '');
	if (! $listen) {
		carp "missing network protocol";
        return undef;
	}
	#my $before = $this->destroyConn($type,$vnode,$addr,$proto,$listen );
	my $cmd    = "CREATE $type CONNECTION $vnode $addr $proto $listen";
    $this->_send($cmd);
	my $obj    = $this->{xpct};
	my $before = $obj->before();
	my @lines  = $this->_getCleanArray($cmd,$this->{cmdInject},$before);
	$this->{stream}     = {};	# no more getLogin()/getConn()
	$this->{streamPtr}  = 0;
	$this->{streamType} = '';
	return join("\n",@lines);
}


=item destroyLogin($type, $vnode)

Delete a Login VNode and all its connections.

Returns output from netutil.

Takes the following parameters:
    $type   - VNode type: GLOBAL/PRIVATE
    $vnode  - VNode name/*

=cut

sub destroyLogin ($$) {
	my $this = shift;
	my $type = uc (@_ ? shift : '*');
	if ($type ne 'GLOBAL'  &&
	    $type ne 'PRIVATE') {
			carp "invalid type: $type";
            return undef;
	}
	my $vnode = @_ ? shift : '';
	if (! $vnode) {
		carp "missing VNode name";
        return undef;
	}
	my $cmd    = "DESTROY $type LOGIN $vnode";
    $this->_send($cmd);
	my $obj    = $this->{xpct};
	my $before = $obj->before();
	my @lines  = $this->_getCleanArray($cmd,$this->{cmdInject},$before);
	$this->{stream}     = {};	# no more getLogin()/getConn() 
	$this->{streamPtr}  = 0;
	$this->{streamType} = '';
	return join("\n",@lines);
}


=item destroyConn($type, $vnode, $addr, $proto, $listen)

Destroy (delete) a connection for a Login VNode.

Returns output from netutil.

Takes the following parameters:
    $type    - VNode type: GLOBAL/PRIVATE
    $vnode   - VNode name/*
    $addr    - IP, hostname of the server, or '*'
    $proto   - protocol name (tcp_ip, win_tcp, ipx, etc.), or '*'
    $listen  - remote server's listen address (generaly 'II'), or '*'

=cut

sub destroyConn($$$$$) {
	my $this = shift;
	my $type = uc (@_ ? shift : '*');
	if ($type ne 'GLOBAL'  &&
	    $type ne 'PRIVATE') {
			carp "invalid type: $type";
            return undef;
	}
	my $vnode = uc (@_ ? shift : '');
	if (! $vnode) {
		carp "missing VNode name";
        return undef;
	}
	my $addr = uc (@_ ? shift : '');
	if (! $addr) {
		carp "missing network address";
        return undef;
	}
	my $proto = @_ ? shift : '';
	if (! $proto) {
		carp "missing network protocol";
        return undef;
	}
	my $listen = uc(@_ ? shift : '');
	if (! $listen) {
		carp "missing listen address";
        return undef;
	}
	my $cmd    = "DESTROY $type CONNECTION $vnode $addr $proto $listen";
    $this->_send($cmd);
	my $obj    = $this->{xpct};
	my $before = $obj->before();
	my @lines  = $this->_getCleanArray($cmd,$this->{cmdInject},$before);
	$this->{stream}     = {};	# no more getLogin()/getConn()
	$this->{streamPtr}  = 0;
	$this->{streamType} = '';
	return join("\n",@lines);
}


sub _quiesceStopServer($;$ ) {
	my $this     = shift;
	my $cmd      = shift;
    my $serverId = @_ ? shift : '';
	$cmd         = "$cmd $serverId";
    $this->_send($cmd);
	my $obj      = $this->{xpct};
	my $before   = $obj->before();
	my @lines    = $this->_getCleanArray($cmd,$this->{cmdInject},$before);
	return join("\n",@lines);
}

=item quiesceServer(;$serverId)

Stops IIGCC server gracefully, i.e. after all connections are closed by clients.
No more connections are stablished.

Takes optional parameter serverId, to specify which server, or '*' for all servers.
Default '*' (all).

=cut

sub quiesceServer($ ) {
	my $this     = shift;
	my $serverId = @_ ? shift : '*';
    
	return $this->_quiesceStopServer('QUIESCE',$serverId);
}


=item stopServer($)

Stops IIGCC server immediatly, breaking all connections.

Takes optional parameter serverId, to specify which server, or '*' for all servers.
Default '*' (all).

=cut

sub stopServer(;$ ) {
	my $this     = shift;
	my $serverId = @_ ? shift : '*';
	return $this->_quiesceStopServer('STOP',$serverId);
}

=back


=head1 DIAGNOSTICS

=over

=item C<< Ingres environment variable II_SYSTEM not set >>

Ingres environment variables should be set in the user session running
this module.
II_SYSTEM provides the root install dir (the one before 'ingres' dir).
LD_LIBRARY_PATH too. See Ingres RDBMS docs.

=item C<< Ingres utility cannot be executed: _COMMAND_FULL_PATH_ >>

The Netutil command could not be found or does not permits execution for
the current user.

=item C<< invalid type: _VNODE_TYPE_ >>

Call to a VNode related method should be given a valid VNode type (GLOBAL/PRIVATE),
or a wildcard (*), when permitted.

=item C<< showLogin() must be previously invoked >>

A method call should be preceded by a preparatory call to showLogin().
If any call is made to createXxx() or deleteXxx(), (whichever Login or Conn), then showLogin()
should be called again.

=item C<< showConn() must be previously invoked >>

A method call should be preceded by a preparatory call to showConn().
If any call is made to createXxx() or deleteXxx(), (whichever Login or Conn), then showConn()
should be called again.

=item C<< missing VNode name >>

VNode name identifying a Login is required for this method.

=item C<< missing _PARAMETER_ >>

The method requires the mentioned parameter to perform an action.

=back


=head1 CONFIGURATION AND ENVIRONMENT
  
Requires Ingres environment variables, such as II_SYSTEM and LD_LIBRARY_PATH.

See Ingres RDBMS documentation.


=head1 DEPENDENCIES

L<Expect::Simple>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to C<bug-ingres-utility-Netutil at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ingres::Utility::Netutil

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ingres-Utility-Netutil>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Ingres-Utility-Netutil>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Ingres-Utility-Netutil>

=item * Search CPAN

L<http://search.cpan.org/dist/Ingres-Utility-Netutil>

=item * Ingres Documentation

L<http://opensource.ingres.com/projects/ingres/documents>

L<http://opensource.ingres.com/projects/ingres/documents/product/Ingres%202006%20Documentation/sysadm/download>

L<http://opensource.ingres.com/projects/ingres/documents/product/Ingres%202006%20Documentation/CommandReference/download>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Computer Associates (CA) for licensing Ingres as
open source, and let us hope for Ingres Corp to keep it that way.

=head1 AUTHOR

Joner Cyrre Worm  C<< <FAJCNLXLLXIH at spammotel.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006, Joner Cyrre Worm C<< <FAJCNLXLLXIH at spammotel.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

Ingres is a registered brand of Ingres Corporation.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1; # End of Ingres::Utility::Netutil
__END__
