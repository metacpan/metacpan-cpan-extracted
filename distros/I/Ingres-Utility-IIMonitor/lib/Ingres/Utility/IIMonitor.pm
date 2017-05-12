package Ingres::Utility::IIMonitor;

use warnings;
use strict;
use Carp;
use Expect::Simple;

=head1 NAME

Ingres::Utility::IIMonitor - API to C<iimonitor> Ingres RDBMS utility

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';

=head1 SYNOPSIS

    use Ingres::Utility::IIMonitor;
    
    # create a connection to an IIDBMS server
    # (server id can be obtained through Ingres::Utility::IINamu)
    $foo = Ingres::Utility::IIMonitor->new($serverid);
    
    # showServer() - shows server status
    #
    # is the server listening to new connections? (OPEN/CLOSED)
    $status =$foo->showServer('LISTEN');
    #
    # is the server being shut down?
    $status =$foo->showServer('SHUTDOWN');
    
    # setServer() - sets server status
    #
    # stop listening to new connections
    $status =$foo->setServer('CLOSED');
    #
    # start shutting down (wait for connections to close)
    $status =$foo->setServer('SHUT');
    
    # stop() - stops IIDBMS server (transactions rolled back)
    #
    $ret = $foo->stop();
    
    # showSessions($target,$mode) - prepares to get sessions info
    print $foo->showSessions('SYSTEM','FORMATTED');
    
    # getSession() - get sessions call-after-call from previous showSessions()
    while (%session = $foo->getSession()) {
        print "Session ". $session{'SESSION_ID'} . ":\n"
        foreach $label, $value (%session) {
            print "\t$label:\t$value\n" if ($label ne 'SESSION_ID');
        }
    }
  
  
=head1 DESCRIPTION

This module provides an API to the iimonitor utility for
Ingres RDBMS, which provides local control of IIDBMS servers
and sessions (system and user conections).


=head1 METHODS

=over

=item C<new($serverId)>

Constructor, connects to an IIDBMS server through iimonitor utility.

Takes the server id as argument to identify which server
to control.

 $iimonitor = Ingres::Utility::IIMonitor->new(12345);
 
The server id can be obtained through L<Ingres::Utility::IINamu> module.

=cut

sub new($) {
    my $class = shift;
    my $this = {};
    $class = ref($class) || $class;
    bless $this, $class;
    my $serverId = shift;
    if (! $serverId) {
        croak "parameter missing: serverId";
    }
    if (! defined($ENV{'II_SYSTEM'})) {
        croak "Ingres environment variable II_SYSTEM not set";
    }
    my $iimonitor_file = $ENV{'II_SYSTEM'} . '/ingres/bin/iimonitor';
    
    if (! -x $iimonitor_file) {
        croak "Ingres utility cannot be executed: $iimonitor_file";
    }
    $this->{cmd} = $iimonitor_file;
    $this->{xpct} = new Expect::Simple {
                Cmd => "$iimonitor_file $serverId",
                Prompt => [ -re => 'IIMONITOR>\s+' ],
                DisconnectCmd => 'QUIT',
                Verbose => 0,
                Debug => 0,
                Timeout => 10
        } or croak "Module Expect::Simple cannot be instanciated";
        $this->{serverId} = $serverId;
    return $this;
}


=item C<showServer($serverStatus)>

Returns the server status.

Takes the server status to query:

 LISTEN = server listening to new connections
 
 SHUTDOWN = server waiting for connections to close to end process.

Returns 'OPEN', 'CLOSED' or 'PENDING' (for shutdown).

=cut

sub showServer($) {
    my $this = shift;
    my $serverStatus = uc (@_ ? shift : '');
    if ($serverStatus) {
        if ($serverStatus ne 'LISTEN') {
            if ($serverStatus ne 'SHUTDOWN') {
                carp "invalid status: ($serverStatus)";
                return ();
            }
        }
    }
    #print $this . ": cmd = $cmd";
    my $obj = $this->{xpct};
    $obj->send( 'SHOW SERVER ' . $serverStatus );
    my $before = $obj->before;
    while ($before =~ /\ \ /) {
        $before =~ s/\ \ /\ /g;
    }
    my @antes = split /\r\n/,$before;
    return join($/,@antes);
}


=item C<setServer($serverStatus)>

Changes the server status to the state indicated by the argument:

 SHUT = server will shutdown after all connections are closed

 CLOSED = stops listening to new connections

 OPEN = reestablishes listening to new connections

=cut

sub setServer($) {
    my $this = shift;
    my $serverStatus = uc (shift);
    if (! $serverStatus) {
        carp 'no status given';
    }
    if ($serverStatus ne 'SHUT') {
        if ($serverStatus ne 'CLOSED') {
            if ($serverStatus ne 'OPEN') {
                carp "invalid status: ($serverStatus)";
                return;
            }
        }
    }
    my $obj = $this->{xpct};
    $obj->send( 'SET SERVER ' . $serverStatus );
    my $before = $obj->before;
    while ($before =~ /\ \ /) {
        $before =~ s/\ \ /\ /g;
    }
    my @antes = split /\r\n/,$before;
    return $before;
    
}


=item C<stopServer()>

Stops server immediatly, rolling back transactions and closing all connections.

=cut

sub stopServer() {
    my $this = shift;
    my $obj = $this->{xpct};
    $obj->send( 'STOP');
    my $before = $obj->before;
    while ($before =~ /\ \ /) {
        $before =~ s/\ \ /\ /g;
    }
    my @antes = split /\r\n/,$before;
    return;
    
}

# Transform into all uppercase and translate spaces into underscores
sub _prepareName($) {
    my $this = shift;
    my $name = shift;
    $name = uc $name;
    $name =~ tr/\ /\_/;
    return $name;
}


=item C<showSessions(;$target,$mode)>

Prepares to show info on sessions on IIDBMS server, for being fetched later by getNextSession().

Returns the output from iimonitor.

Takes the following parameters:
 [<TARGET>], [<MODE>]
 
 TARGET = Which session type: USER (default), SYSTEM or ALL
 MODE   = Which server info: FORMATTED, STATS. Default is a short format.

=cut

sub showSessions(;$$) {
    my $this = shift;
    my $target;
    my $mode;
    $target = uc (@_ ? shift : 'USER');
    if ($target eq 'FORMATTED' or
        $target eq 'STATS') {
        if (@_) {
            carp "invalid paramter after $target: (" . join(' ',@_) . ")";
            return '';
        }
        $mode   = $target;
        $target = 'USER';
    }
    else {
        if ($target ne 'USER'   and
            $target ne 'SYSTEM' and
            $target ne 'ALL'    and
            $target ne '') {
            carp "invalid target: ($target)";
            return '';
        }
        $mode =uc (@_ ? shift : '');
        if ($mode ne 'FORMATTED' and
            $mode ne 'STATS'     and
            $mode ne '') {
            carp "invalid mode: ($mode)";
            return '';
        }
    }
    my $obj = $this->{xpct};
    $obj->send("SHOW $target SESSIONS $mode");
    my $before = $obj->before;
#   while ($before =~ /\ \ /) {
#       $before =~ s/\ \ /\ /g;
#   }
    $this->{sessWho}  = $target;
    $this->{sessMode} = $mode;
    my @tmp = split (/\r\n/,$before);
    $this->{sessOutArray} = \@tmp;
    $this->{sessBuff} = ();
    $this->{sessPtr}  = 0;
    return $before;
}


=item C<getSession()>

Returns sequentially (call-after-call) each session reported by showSessions() as a hash of
as many elements as returned by each session target and mode, where the key is the name
showed on labels of iimonitor's output, all uppercase and spaces translated into underscores (_).

Unlabeled info gets its key from the previously labeled field appended by '_#<index>', where
index is the sequential order (starting by 0) on which the info appeared.

This way, all info is in pairs of (LABEL,VALUE), whithout parenthesis or trailing spaces.

UFO - Unidentified Format Output - will be translated into words forming pairs of labels and values,
PLEASE REPORT THIS, because this is not expected to happen. Meanwhile see what you can do with
these pairs, and will probably need extra parsing. If you report this, there's hope they will be
properly handled on the next version.


=cut

sub getSession() {
    my $this = shift;
    my @foo;
    my %sess = ();
    my $name;
    my $value;
    my $i;
    my $j;
    if ($this->{sessPtr} >= scalar @{$this->{sessOutArray}}) {
        $this->{sessPtr} = 0;
        return %sess;
    }
FOR_gNS:
for ($i = $this->{sessPtr}; ($i < scalar @{$this->{sessOutArray}}); $i++) {
        $_ = $this->{sessOutArray}[$i];
        if (/^session\s/i) {
            if ($this->{sessMode} eq 'STATS') {
                if (@foo = (/^(session)\s([0-9A-Fa-f]+)\s+\((.*)\)(\s*)(.*)/i)) {
                    if (scalar keys %sess > 0) {
                        last FOR_gNS;
                    }
                    $sess{'SESSION_ID'} = $2;
                    $sess{'SESSION_USER'} = $3;
                    if (defined $5) {
                        my @stats = split /\s+/,$5;
                        for ($j = 0; ($j < (scalar @stats)); $j += 2) {
                            $name = $stats[$j];
                            $name = $this->_prepareName($name);
                            $value = '';
                            if (defined $stats[$j+1]) {
                                $value = $stats[$j+1];
                            }
                            $sess{$name} = $value;
                        }
                    }
                }
            }
            else {
                if (@foo = (/^(session)\s([0-9A-Fa-f]+)\s+\((.*)\)\s+(cs_state)\:\s(.*)\s\((.*)\)\s(cs_mask)\:\s(.*)/i)) {
                    if (scalar keys %sess > 0) {
                        last FOR_gNS;
                    }
                    $sess{'SESSION_ID'} = $2;
                    $sess{'SESSION_USER'} = $3;
                    $sess{'CS_STATE'} = $5;
                    $sess{'CS_STATE_#0'} = $6;
                    $sess{'CS_MASK'} = $8;
                }
            }
        }
        elsif (@foo = (/^\s+(user)\:\s(.*)\((.*)\s+.*\)/i)) {
            $sess{'USER'} = $2;
            $sess{'USER_#0'} = $3;
        }
        elsif (@foo = (/^\s+(db\sname)\:\s(.*)\((owned\sby)\:\s(.*)\s+\)/i)) {
            $sess{'DB_NAME'} = $2;
            $sess{'OWNED_BY'} = $4;
        }
        elsif (@foo = (/^\s+(application\scode)\:\s(.*)\s(current\sfacility)\:\s(.*)\s+\((.*)\)/i)) {
            $sess{'APPLICATION_CODE'} = $2;
            $sess{'CURRENT_FACILITY'} = $4;
            $sess{'CURRENT_FACILITY_#0'} = $5;
        }
        elsif (@foo = (/^\s+(.*)\:\s+(.*:.*)/)) {
            $name = $this->_prepareName($1);
            $sess{$name} = $2;
        }
        elsif (@foo = (/^\s+(.*)\:\s*(.*)/)) {
            $name = $this->_prepareName($1);
            $sess{$name} = $2;
        }
        else { # UFO - Unidentifyed Format Output
            @foo = split ' ';
            for ($j = 0; ($j < scalar @foo) ; $j += 2) {
                if (defined $foo[$j]) {
                    $name = $this->_prepareName($foo[$j]);
                    $value = '';
                    if (defined $foo[$j+1]) {
                        $value = $foo[$j+1];
                        while (substr($value,length($value)-1) eq ' ') {
                            chop $value;
                        }
                    }
                    $sess{$name} = $value;
                }
            }
        }
    }
    $this->{sessPtr} = $i;
    return %sess;
}

=back

=head1 DIAGNOSTICS

=over

=item C<< parameter missing: serverId >>

Call to method new() is missing the serverId argument to indicate the IIDBMS
to connect to.

=item C<< Ingres environment variable II_SYSTEM not set >>

Ingres environment variables should be set in the user session running
this module.
II_SYSTEM provides the root install dir (the one before 'ingres' dir).
LD_LIBRARY_PATH too. See Ingres RDBMS docs.

=item C<< Ingres utility cannot be executed: _COMMAND_FULL_PATH_ >>

The IIMONITOR command could not be found or does not permits execution for
the current user.

=item C<< parameter missing: serverStatus >>

Call to method setServer() is missing the serverStatus argument.

=item C<< invalid status: (_SERVER_STATUS_PARAM_) >>

The showServer() or setServer() methods received an invalid argument.

=item C<< invalid target: (_TARGET_) >>

The showServer() takes the first argument only as USER/SYSTEM/ALL.

=item C<< invalid mode: (_MODE_) >>

The showServer() takes the second or only one argument only as FORMATTED/STATS.

=item C<< invalid paramter after _TARGET_: (_PARAMETER_) >>

If showServer() takes the first as FORMATTED/STATS then no other parameter is
accepted.

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

Please report any bugs or feature requests to C<bug-ingres-utility-iimonitor at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ingres::Utility::IIMonitor

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ingres-Utility-IIMonitor>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Ingres-Utility-IIMonitor>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Ingres-Utility-IIMonitor>

=item * Search CPAN

L<http://search.cpan.org/dist/Ingres-Utility-IIMonitor>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Computer Associates (CA) for licensing Ingres as
open source, and let us hope for Ingres Corp to keep it that way.

=head1 AUTHOR

Joner Cyrre Worm  C<< <FAJCNLXLLXIH at spammotel.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006, Joner Cyrre Worm C<< <FAJCNLXLLXIH at spammotel.com> >>. All rights reserved.


Ingres is a registered brand of Ingres Corporation.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


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

1; # End of Ingres::Utility::IIMonitor
__END__
