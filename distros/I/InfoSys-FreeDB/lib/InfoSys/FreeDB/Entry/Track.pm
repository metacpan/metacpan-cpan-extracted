package InfoSys::FreeDB::Entry::Track;

use 5.006;
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);

# Package version
our ($VERSION) = '$Revision: 0.92 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

InfoSys::FreeDB::Entry::Track - FreeDB entry track

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
 
 # Write the track titles to STDERR
 use IO::Handle;
 my $fh = IO::Handle->new_from_fd( fileno(STDERR), 'w' );
 foreach my $track ( $res_r->get_entry()->get_track() ) {
     $fh->print( $track->get_title(), "\n" );
 }

=head1 ABSTRACT

FreeDB entry track

=head1 DESCRIPTION

C<InfoSys::FreeDB::Entry::Track> contains information on FreeDB entry tracks.

=head1 CONSTRUCTOR

=over

=item new( [ OPT_HASH_REF ] )

Creates a new C<InfoSys::FreeDB::Entry::Track> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<extt>>

Passed to L<set_extt()>.

=item B<C<offset>>

Passed to L<set_offset()>.

=item B<C<title>>

Passed to L<set_title()>.

=back

=back

=head1 METHODS

=over

=item get_extt()

Returns the track extt.

=item get_offset()

Returns the track offset.

=item get_title()

Returns the track title.

=item set_extt(VALUE)

Set the track extt. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_offset(VALUE)

Set the track offset. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_title(VALUE)

Set the track title. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item write_fh(FILE_HANDLE)

Writes the entry to the specified file handle. C<FILE_HANDLE> is a C<IO::Handle> object. On error an exception C<Error::Simple> is thrown.

=back

=head1 SEE ALSO

L<InfoSys::FreeDB>,
L<InfoSys::FreeDB::Connection>,
L<InfoSys::FreeDB::Connection::CDDBP>,
L<InfoSys::FreeDB::Connection::HTTP>,
L<InfoSys::FreeDB::Entry>,
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
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::Track::_initialize, first argument must be 'HASH' reference.");

    # extt, SINGLE
    exists( $opt->{extt} ) && $self->set_extt( $opt->{extt} );

    # offset, SINGLE
    exists( $opt->{offset} ) && $self->set_offset( $opt->{offset} );

    # title, SINGLE
    exists( $opt->{title} ) && $self->set_title( $opt->{title} );

    # Return $self
    return($self);
}

sub _value_is_allowed {
    return(1);
}

sub get_extt {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Entry_Track}{extt} );
}

sub get_offset {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Entry_Track}{offset} );
}

sub get_title {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Entry_Track}{title} );
}

sub set_extt {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'extt', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::Track::set_extt, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Entry_Track}{extt} = $val;
}

sub set_offset {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'offset', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::Track::set_offset, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Entry_Track}{offset} = $val;
}

sub set_title {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'title', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::Track::set_title, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Entry_Track}{title} = $val;
}

sub write_fh {
}

