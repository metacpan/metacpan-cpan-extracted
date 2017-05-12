package InfoSys::FreeDB::Match;

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

InfoSys::FreeDB::Match - FreeDB query match

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

FreeDB query match

=head1 DESCRIPTION

C<InfoSys::FreeDB::Match> contains information on FreeDB query match.

=head1 CONSTRUCTOR

=over

=item new( [ OPT_HASH_REF ] )

Creates a new C<InfoSys::FreeDB::Match> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<categ>>

Passed to L<set_categ()>.

=item B<C<discid>>

Passed to L<set_discid()>.

=item B<C<dtitle>>

Passed to L<set_dtitle()>.

=back

=back

=head1 METHODS

=over

=item get_categ()

Returns the match category.

=item get_discid()

Returns the match discid.

=item get_dtitle()

Returns the match disk title.

=item set_categ(VALUE)

Set the match category. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_discid(VALUE)

Set the match discid. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_dtitle(VALUE)

Set the match disk title. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=back

=head1 SEE ALSO

L<InfoSys::FreeDB>,
L<InfoSys::FreeDB::Connection>,
L<InfoSys::FreeDB::Connection::CDDBP>,
L<InfoSys::FreeDB::Connection::HTTP>,
L<InfoSys::FreeDB::Entry>,
L<InfoSys::FreeDB::Entry::Track>,
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
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: InfoSys::FreeDB::Match::_initialize, first argument must be 'HASH' reference.");

    # categ, SINGLE
    exists( $opt->{categ} ) && $self->set_categ( $opt->{categ} );

    # discid, SINGLE
    exists( $opt->{discid} ) && $self->set_discid( $opt->{discid} );

    # dtitle, SINGLE
    exists( $opt->{dtitle} ) && $self->set_dtitle( $opt->{dtitle} );

    # Return $self
    return($self);
}

sub _value_is_allowed {
    return(1);
}

sub get_categ {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Match}{categ} );
}

sub get_discid {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Match}{discid} );
}

sub get_dtitle {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Match}{dtitle} );
}

sub set_categ {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'categ', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Match::set_categ, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Match}{categ} = $val;
}

sub set_discid {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'discid', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Match::set_discid, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Match}{discid} = $val;
}

sub set_dtitle {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'dtitle', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Match::set_dtitle, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Match}{dtitle} = $val;
}

