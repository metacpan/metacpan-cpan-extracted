package InfoSys::FreeDB;

use 5.006;
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);
use Sys::Hostname;

# Package version
our ($VERSION) = '$Revision: 0.92 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

InfoSys::FreeDB - FreeDB connection factory

=head1 SYNOPSIS

 require InfoSys::FreeDB;
 require InfoSys::FreeDB::Entry;
 
 # Read entry from the default CD device
 my $entry = InfoSys::FreeDB::Entry->new_from_cdparanoia();
 
 # Create a HTTP connection
 my $fact = InfoSys::FreeDB->new();
 my $conn = $fact->create_connection( {
     client_name => 'testing-InfoSys::FreeDB',
     client_version => $InfoSys::FreeDB::VERSION,
 } );
 
 # Query FreeDB
 my $res_q = $conn->query( $entry );
 scalar( $res_q->get_match() ) ||
     die 'no matches found for the disck in the default CD-Rom drive';
 
 # Read the first match
 my $res_r = $conn->read( ( $res_q->get_match() )[0] );
 
 # Write the entry to STDERR
 use IO::Handle;
 my $fh = IO::Handle->new_from_fd( fileno(STDERR), 'w' );
 $res_r->get_entry()->write_fh( $fh );

=head1 ABSTRACT

FreeDB connection factory

=head1 DESCRIPTION

C<InfoSys::FreeDB> is the connection factory of the C<InfoSys::FreeDB> module hierarchy. This class creates connections using the protocols supported by FreeDB*.

=over

=item (*)

Currently CDDBP and HTTP protocols are supported.

=back

=head1 CONSTRUCTOR

=over

=item new()

Creates a new C<InfoSys::FreeDB> object.

=back

=head1 METHODS

=over

=item create_connection(OPT_HASH_REF)

Creates a C<InfoSys::FreeDB::Connection> object. C<OPT_HASH_REF> is a hash reference used to pass connection creation options. On error an exception C<Error::Simple> is thrown.

=over

=item SPEED-UP NOTE

If protocol level C<1> is specified, the C<connect> method tries to use the highest available protocol level. To do so, it queries the FreeDB to find out exaclty which level is supported. On C<CDDBP> connections this doesn't take that long. On C<HTTP> connections it does. To speed up C<HTTP> connections specify a higher C<proto_level> -say C<5>.

=back

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<auto_connected>>

Connect the created object just after instantiation. Defaults to C<1>.

=item B<C<client_host>>

The hostname of the client. Defaults to C<&Sys::Hostname::hostname()>.

=item B<C<client_name>>

Mandatory option to name the connecting client software.

=item B<C<client_user>>

The user name of the client. Defaults to C<scalar( getpwuid($E<gt>) )>.

=item B<C<client_version>>

Mandatory option with the client software version string.

=item B<C<freedb_cgi>>*

The FreeDB C<cgi> to use. Defaults to C<~cddb/cddb.cgi>.

=item B<C<freedb_host>>

The FreeDB host. Defaults to C<freedb.freedb.org>.

=item B<C<freedb_port>>

The port on the FreeDB host. Defaults to C<80> for C<HTTP> and to C<888> for C<CDDBP> connection types.

=item B<C<protocol>>

The protocol to use. Either C<HTTP> or C<CDDBP>. Defaults to C<HTTP>.

=item B<C<proto_level>>

The FreeDB protocol level. Defaults to B<1>.

=item B<C<proxy_host>>**

The proxy host to use.

=item B<C<proxy_passwd>>**

The proxy password to use.

=item B<C<proxy_port>>**

The port on the proxy host. Defaults to 8080.

=item B<C<proxy_user>>**

The proxy user name to use.

=back

=over

=item (*)

Only supported for the HTTP protocol.

=item (**)

Proxy is only supported for the HTTP protocol.

=back


=back

=head1 SEE ALSO

L<InfoSys::FreeDB::Connection>,
L<InfoSys::FreeDB::Connection::CDDBP>,
L<InfoSys::FreeDB::Connection::HTTP>,
L<InfoSys::FreeDB::Entry>,
L<InfoSys::FreeDB::Entry::Track>,
L<InfoSys::FreeDB::Match>,
L<InfoSys::FreeDB::Response>,
L<InfoSys::FreeDB::Response::DiscId>,
L<InfoSys::FreeDB::Response::Hello>,
L<InfoSys::FreeDB::Response::LsCat>,
L<InfoSys::FreeDB::Response::Motd>,
L<InfoSys::FreeDB::Response::Proto>,
L<InfoSys::FreeDB::Response::Query>,
L<InfoSys::FreeDB::Response::Quit>,
L<InfoSys::FreeDB::Response::Read>,
L<InfoSys::FreeDB::Response::SignOn>,
L<InfoSys::FreeDB::Response::Sites>,
L<InfoSys::FreeDB::Response::Stat>,
L<InfoSys::FreeDB::Response::Ver>,
L<InfoSys::FreeDB::Response::Whom>,
L<InfoSys::FreeDB::Response::Write::1>,
L<InfoSys::FreeDB::Response::Write::2>,
L<InfoSys::FreeDB::Site>

=head1 BUGS

None known (yet.)

=head1 TODO

=head2 Implement

=over

=item log()

=item update()

=back

=head2 Test

=over

=item write()

=back

=head2 Analyse

=over

=item CDDBP through firewall

=back

=head1 HISTORY

First development: September 2003
Last update: October 2003

=head1 AUTHOR

Vincenzo Zocca

=head1 COPYRIGHT

Copyright 2003 by Vincenzo Zocca

=head1 LICENSE

This file is part of the C<InfoSys::FreeDB> module hierarchy for Perl by
Vincenzo Zocca.

The InfoSys::FreeDB module hierarchy is free software; you can redistribute it
and/or modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2 of
the License, or (at your option) any later version.

The InfoSys::FreeDB module hierarchy is distributed in the hope that it will
be useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the InfoSys::FreeDB module hierarchy; if not, write to
the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA 02111-1307 USA

=cut

sub new {
    my $class = shift;

    my $self = {};
    bless( $self, ( ref($class) || $class ) );
    return( $self->_initialize(@_) );
}

sub _initialize {
    my $self = shift;
    my $opt = defined($_[0]) ? shift : {};

    # Check $opt
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: InfoSys::FreeDB::_initialize, first argument must be 'HASH' reference.");

    # Return $self
    return($self);
}

sub create_connection {
    my $self = shift;
    my $opt = defined($_[0]) ? shift : {};

    # Check $opt
    ref($opt) eq 'HASH' ||
        throw Error::Simple("ERROR: InfoSys::FreeDB::create_connection, first argument must be 'HASH' reference.");

    # Set default values for $opt
    $opt->{client_host} = &Sys::Hostname::hostname()
        if (! $opt->{client_host} );
    $opt->{client_user} = scalar( getpwuid($>) )
        if (! $opt->{client_user} );
    $opt->{freedb_host} = 'freedb.freedb.org'
        if (! $opt->{freedb_host} );

    # Set default value to protocol
    $opt->{protocol} = 'HTTP' if ( ! $opt->{protocol} );

    # Select the correct connection class
    my $conn = undef;
    if ( $opt->{protocol} eq 'HTTP' ) {
        $opt->{freedb_port} = 80
            if (! $opt->{freedb_port} );
        require InfoSys::FreeDB::Connection::HTTP;
        $conn = InfoSys::FreeDB::Connection::HTTP->new($opt);
    }
    elsif ( $opt->{protocol} eq 'CDDBP' ){
        $opt->{freedb_port} = 888
            if (! $opt->{freedb_port} );
        require InfoSys::FreeDB::Connection::CDDBP;
        $conn = InfoSys::FreeDB::Connection::CDDBP->new($opt);
    }
    else {
        throw Error::Simple("ERROR: InfoSys::FreeDB::create_connection, protocol '$opt->{protocol}' is not supported. Only 'HTTP' and 'CDDBP' are.");
    }

    # Connect if necessary
    $opt->{auto_connected} = 1 if ( !exists( $opt->{auto_connected} ) );
    $opt->{auto_connected} && $conn->connect();

    # Return the connection
    return($conn);
}

