package InfoSys::FreeDB::Site;

use 5.006;
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);

# Used by _initialize
our %DEFAULT_VALUE = (
    'address' => '-',
);

# Package version
our ($VERSION) = '$Revision: 0.92 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

InfoSys::FreeDB::Site - FreeDB site

=head1 SYNOPSIS

 require InfoSys::FreeDB;
 
 # Create a HTTP connection
 my $fact = InfoSys::FreeDB->new();
 my $conn = $fact->create_connection( {
     client_name => 'testing-InfoSys::FreeDB',
     client_version => $InfoSys::FreeDB::VERSION,
 } );
 
 # Get sites from FreeDB
 my $res = $conn->sites();
 
 # Write the sites to STDERR
 use IO::Handle;
 my $fh = IO::Handle->new_from_fd( fileno(STDERR), 'w' );
 foreach my $site ( $res->get_site() ) {
     $fh->print( join(', ',
         $site->get_address(),
         $site->get_description(),
         $site->get_latitude(),
         $site->get_longitude(),
         $site->get_port(),
         $site->get_protocol(),
         $site->get_site(),
     ), "\n" );
 }

=head1 ABSTRACT

FreeDB site

=head1 DESCRIPTION

C<InfoSys::FreeDB::Site> objects contain information on FreeDB sites.

=head1 CONSTRUCTOR

=over

=item new( [ OPT_HASH_REF ] )

Creates a new C<InfoSys::FreeDB::Site> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<address>>

Passed to L<set_address()>. Defaults to B<'-'>.

=item B<C<description>>

Passed to L<set_description()>.

=item B<C<latitude>>

Passed to L<set_latitude()>.

=item B<C<longitude>>

Passed to L<set_longitude()>.

=item B<C<port>>

Passed to L<set_port()>.

=item B<C<protocol>>

Passed to L<set_protocol()>.

=item B<C<site>>

Passed to L<set_site()>.

=back

=back

=head1 METHODS

=over

=item get_address()

Returns the additional addressing information needed to access the server.

=item get_description()

Returns the short description of the geographical location of the site.

=item get_latitude()

Returns the latitude of the server site.

=item get_longitude()

Returns the longitude of the server site.

=item get_port()

Returns the port at which the server resides on that site.

=item get_protocol()

Returns the supported protocol.

=item get_site()

Returns the Internet address of the remote site.

=item set_address(VALUE)

Set the additional addressing information needed to access the server. C<VALUE> is the value. Default value at initialization is C<->. On error an exception C<Error::Simple> is thrown.

=item set_description(VALUE)

Set the short description of the geographical location of the site. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_latitude(VALUE)

Set the latitude of the server site. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_longitude(VALUE)

Set the longitude of the server site. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_port(VALUE)

Set the port at which the server resides on that site. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_protocol(VALUE)

Set the supported protocol. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_site(VALUE)

Set the Internet address of the remote site. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=back

=head1 SEE ALSO

L<InfoSys::FreeDB>,
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
L<InfoSys::FreeDB::Response::Write::2>

=head1 BUGS

None known (yet.)

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
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: InfoSys::FreeDB::Site::_initialize, first argument must be 'HASH' reference.");

    # address, SINGLE, with default value
    $self->set_address( exists( $opt->{address} ) ? $opt->{address} : $DEFAULT_VALUE{address} );

    # description, SINGLE
    exists( $opt->{description} ) && $self->set_description( $opt->{description} );

    # latitude, SINGLE
    exists( $opt->{latitude} ) && $self->set_latitude( $opt->{latitude} );

    # longitude, SINGLE
    exists( $opt->{longitude} ) && $self->set_longitude( $opt->{longitude} );

    # port, SINGLE
    exists( $opt->{port} ) && $self->set_port( $opt->{port} );

    # protocol, SINGLE
    exists( $opt->{protocol} ) && $self->set_protocol( $opt->{protocol} );

    # site, SINGLE
    exists( $opt->{site} ) && $self->set_site( $opt->{site} );

    # Return $self
    return($self);
}

sub _value_is_allowed {
    return(1);
}

sub get_address {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Site}{address} );
}

sub get_description {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Site}{description} );
}

sub get_latitude {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Site}{latitude} );
}

sub get_longitude {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Site}{longitude} );
}

sub get_port {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Site}{port} );
}

sub get_protocol {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Site}{protocol} );
}

sub get_site {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Site}{site} );
}

sub set_address {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'address', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Site::set_address, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Site}{address} = $val;
}

sub set_description {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'description', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Site::set_description, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Site}{description} = $val;
}

sub set_latitude {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'latitude', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Site::set_latitude, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Site}{latitude} = $val;
}

sub set_longitude {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'longitude', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Site::set_longitude, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Site}{longitude} = $val;
}

sub set_port {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'port', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Site::set_port, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Site}{port} = $val;
}

sub set_protocol {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'protocol', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Site::set_protocol, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Site}{protocol} = $val;
}

sub set_site {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'site', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Site::set_site, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Site}{site} = $val;
}

