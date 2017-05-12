package Ingres::Utility::IINamu;

use warnings;
use strict;
use Expect::Simple;
use Carp;

=head1 NAME

Ingres::Utility::IINamu -  API to C<iinamu> Ingres RDBMS utility

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

List registered INGRES (IIDBMS) services:

    use Ingres::Utility::IINamu;

    my $foo = Ingres::Utility::IINamu->new();
    
    # list all INGRES-type servers (iidbms)
    print $foo->show('INGRES');
    
    # process each server separately
    while (my @server = $foo->getServer()) {
    	
	print "Server type: $server[0]\tname:$server[1]\tid:$server[2]";

	if (defined($server[3])) {

		print "\t$server[3]";

	}

	print "\n";

    }
    
    # stop IIGCN server (no more connections to all of Ingres services)
    $ret = $foo->stop();
    
    ...


=head1 DESCRIPTION

This module provides an API to the C<iinamu> utility for Ingres RDBMS,
which provides local interaction and control of IIGCN server,
in charge of registering all Ingres services.

Through this interface, it is possible to obtain a list of all
registered services, for later processing (eg. C<iimonitor>), and
also stopping the IIGCN server (EXTREME CAUTION: Ingres may need
to be restarted!).


=head1 FUNCTIONS

=over

=item C<new()>

Create a new instance, checking environment prerequisites
and preparing for interfacing with C<iinamu> utility.

    $namu = Ingres::Utility::IINamu->new();

=cut

sub new() {
	my $class = shift;
	my $this = {};
	$class = ref($class) || $class;
	bless $this, $class;
	if (! defined($ENV{'II_SYSTEM'})) {
		carp "Ingres environment variable II_SYSTEM not set";
        return {};
	}
	my $iigcn_file = $ENV{'II_SYSTEM'} . '/ingres/bin/iinamu';
	
	if (! -x $iigcn_file) {
		carp "Ingres utility cannot be executed: $iigcn_file";
        return {};
	}
	$this->{cmd} = $iigcn_file;
	$this->{xpct} = new Expect::Simple {
				Cmd => $iigcn_file,
				Prompt => [ -re => 'IINAMU>\s+' ],
				DisconnectCmd => 'QUIT',
				Verbose => 0,
				Debug => 0,
				Timeout => 10
                } or do {
                    carp "Module Expect::Simple cannot be instanciated.";
                    return {};
                };
	$this->{stream}    = '';
	$this->{streamPtr} = 0;
	$this->{svrType}   = '';
	return $this;
}

=item C<show(;$serverType)>

Returns the output of C<SHOW> command, and prepares for
parsing the servers sequentially with C<getServer()>.

Takes one optional argument for the service: C<'INGRES'>(IIDBMS, default),
C<'COMSVR'> (IIGCC), etc.

    print $namu->show('COMSVR'); # show IIGCN servers

=cut

sub show(;$) {
	my $this = shift;
	my $server_type = uc (@_ ? shift : 'INGRES');
	#print $this . ": cmd = $cmd";
	my $obj = $this->{xpct};
	my $cmd = 'SHOW ' . $server_type;
	$obj->send($cmd);
	my $before = $obj->before;
	while ($before =~ /\ \ /) {
		$before =~ s/\ \ /\ /g;
	}
	my @antes = split(/\r\n/,$before);
	if ($#antes >= 0) {
		if ($antes[0] eq $cmd) {
			shift @antes;
		}
	}
	$this->{stream}    = join($/,@antes);
	$this->{streamPtr} = 0;
	$this->{svrType}   = $server_type;
	return $this->{stream};
}

=item C<getServer()>

Returns sequentially (call-after-call) each server reported by C<show()> as an array of
3~4 elements:

    # getServer()[0]: server type (INGRES, COMSVR, etc.)
    # getServer()[1]: server name (as registered with IINAMU or add() method)
    # getServer()[2]: server GCA address (given by INGSTART)
    # getServer()[3]: extra info
    
    $namu->show('INGRES'); # prepare to show all INGRES (IIDBMS ) servers
    
    while (@svrs = $namu->getServer()) {
        print "Server name: $svrs[1]\t address: $svrs[2]";
        print "\t($svrs[3])" if (defined $svrs[3]);
        print "\n"
    }

=cut

sub getServer() {
	my $this = shift;
	if (! $this->{stream}) {
		return ();
	}
	my @antes = split($/,$this->{stream});
	if ($#antes < $this->{streamPtr}) {
		$this->{streamPtr} = 0;
		return ();
	}
	my $line = $antes[$this->{streamPtr}++];
	return split(/\ /, $line);
}

=item C<stop()>

Shuts down the IIGCN daemon, making it no longer possible to
stablish new connections to any Ingres service.
After this, a total restart of Ingres will most probably be necessary.

    $namu->stop(); # no more connections (local remote, etc...)

=cut

sub stop() {
	my $this = shift;
	my $obj = $this->{xpct};
	$obj->send( 'STOP');
	my $before = $obj->before;
	while ($before =~ /\ \ /) {
		$before =~ s/\ \ /\ /g;
	}
	my @antes = split(/\r\n/,$before);
	return;
}

=item C<add($serverType,$serverName,$serverAddr)>

Register another server with IIGCN, so that it can be available
to clients.

Parameters:

    # serverType: type of server (INGRES, COMSVR, etc.)
    # serverName: '*' or a name to individualize the server from the others
    # serverAddr: GCA address attributed during ingstart utility
    
    print $namu->add('COMSVR', '*', '123456'); # register IIGCN server

=cut

sub add($$$) {
	my $this = shift;
	my $server_type = uc (@_ ? shift : '');
	my $server_name = @_ ? shift : '';
	my $server_addr = @_ ? shift : '';
	my $obj = $this->{xpct};
    my $cmd = "ADD $server_type $server_name $server_addr";
	$obj->send($cmd);
	my $before = $obj->before;
	while ($before =~ /\ \ /) {
		$before =~ s/\ \ /\ /g;
	}
	my @antes = split(/\r\n/,$before);
	return $before;
}

=item C<del($serverType,$serverName,$serverAddr)>


Unregister another server with IIGCN, so that it will not be
available to clients.

A server can be registered later again.

Parameters:

    # serverType: type of server (INGRES, COMSVR, etc.)
    # serverName: '*' or a name to individualize the server from the others
    # serverAddr: GCA address attributed during ingstart utility
    
    print $namu->del('COMSVR', '*', '123456'); # this one is not seen anymore.

=cut

sub del($$$) {
	my $this = shift;
	my $server_type = uc (@_ ? shift : '');
	my $server_name = @_ ? shift : '';
	my $server_addr = @_ ? shift : '';
	my $obj = $this->{xpct};
    my $cmd = "DEL $server_type $server_name $server_addr";
	$obj->send($cmd);
	my $before = $obj->before;
	while ($before =~ /\ \ /) {
		$before =~ s/\ \ /\ /g;
	}
	my @antes = split(/\r\n/,$before);
	return $before;
}

=back

=head1 DIAGNOSTICS

=over

=item C<< Ingres environment variable II_SYSTEM not set >>

Ingres environment variables should be set on the user session running
this module.
C<II_SYSTEM> provides the root install dir (the one before C<ingres> dir).
C<LD_LIBRARY_PATH> also. See Ingres RDBMS docs.

=item C<< Ingres utility cannot be executed: _COMMAND_FULL_PATH_ >>

The C<iinamu> command could not be found or does not permits execution for
the current user.

=item C<< Module Expect::Simple cannot be instanciated. >>

The L<Expect::Simple> module could not be instanciated.
The module is reponsible for interections with C<iinamu>
utility. Debugging will be required.

=back


=head1 CONFIGURATION AND ENVIRONMENT
  
Requires Ingres environment variables, such as C<II_SYSTEM> and C<LD_LIBRARY_PATH>.

See Ingres RDBMS documentation.


=head1 DEPENDENCIES

L<Expect::Simple>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to C<bug-ingres-utility-iinamu at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ingres::Utility::IINamu

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ingres-Utility-IINamu>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Ingres-Utility-IINamu>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Ingres-Utility-IINamu>

=item * Search CPAN

L<http://search.cpan.org/dist/Ingres-Utility-IINamu>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Computer Associates (CA) for licensing Ingres as
open source, and let us hope for Ingres Corp to keep it that way.


=head1 AUTHOR

Joner Cyrre Worm  C<< <FAJCNLXLLXIH at spammotel.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006, Joner Cyrre Worm C<< <FAJCNLXLLXIH at spammotel.com> >>. All rights reserved.


Ingres is a registered brand of Ingres Corporation.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.


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

1; # End of Ingres::Utility::IINamu
__END__
