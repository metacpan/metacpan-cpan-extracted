package InfoSys::FreeDB::Response::Query;

use 5.006;
use base qw( InfoSys::FreeDB::Response );
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);
use InfoSys::FreeDB::Response qw(:line_parse);

# Used by _value_is_allowed
our %ALLOW_ISA = (
    'match' => [ 'InfoSys::FreeDB::Match' ],
);

# Used by _value_is_allowed
our %ALLOW_REF = (
);

# Used by _value_is_allowed
our %ALLOW_RX = (
);

# Used by _value_is_allowed
our %ALLOW_VALUE = (
);

# Package version
our ($VERSION) = '$Revision: 0.92 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

InfoSys::FreeDB::Response::Query - FreeDB query response

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

FreeDB query response

=head1 DESCRIPTION

C<InfoSys::FreeDB::Response::Query> contains information about FreeDB query responses.

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<InfoSys::FreeDB::Response::Query> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<exact_match>>

Passed to L<set_exact_match()>.

=item B<C<match>>

Passed to L<set_match()>. Must be an C<ARRAY> reference.

=back

Options for C<OPT_HASH_REF> inherited through package B<C<InfoSys::FreeDB::Response>> may include:

=over

=item B<C<code>>

Passed to L<set_code()>. Mandatory option.

=item B<C<error>>

Passed to L<set_error()>.

=item B<C<result>>

Passed to L<set_result()>. Mandatory option.

=back

=item new_from_content_ref(CONTENT_REF)

Creates a new C<InfoSys::FreeDB::Response::Query> object from the specified content reference. C<CONTENT_REF> is a string reference. On error an exception C<Error::Simple> is thrown.

=back

=head1 METHODS

=over

=item exists_match(ARRAY)

Returns the count of items in C<ARRAY> that are in the match list.

=item get_code()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns the response code.

=item get_match( [ INDEX_ARRAY ] )

Returns an C<ARRAY> containing the match list. C<INDEX_ARRAY> is an optional list of indexes which when specified causes only the indexed elements in the ordered list to be returned. If not specified, all elements are returned.

=item get_result()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns the response result text.

=item is_error()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns whether the response has an error or not.

=item is_exact_match()

Returns whether the query found an exact match or not.

=item pop_match()

Pop and return an element off the match list. On error an exception C<Error::Simple> is thrown.

=item push_match(ARRAY)

Push additional values on the match list. C<ARRAY> is the list value. On error an exception C<Error::Simple> is thrown.

=over

=item The values in C<ARRAY> must be a (sub)class of:

=over

=item InfoSys::FreeDB::Match

=back

=back

=item set_code(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. Set the response code. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_error(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. State that the response has an error. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_exact_match(VALUE)

State that the query found an exact match. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_idx_match( INDEX, VALUE )

Set value in the match list. C<INDEX> is the integer index which is greater than or equal to C<0>. C<VALUE> is the value.

=over

=item The values in C<ARRAY> must be a (sub)class of:

=over

=item InfoSys::FreeDB::Match

=back

=back

=item set_match(ARRAY)

Set the match list absolutely. C<ARRAY> is the list value. On error an exception C<Error::Simple> is thrown.

=over

=item The values in C<ARRAY> must be a (sub)class of:

=over

=item InfoSys::FreeDB::Match

=back

=back

=item set_num_match( NUMBER, VALUE )

Set value in the match list. C<NUMBER> is the integer index which is greater than C<0>. C<VALUE> is the value.

=over

=item The values in C<ARRAY> must be a (sub)class of:

=over

=item InfoSys::FreeDB::Match

=back

=back

=item set_result(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. Set the response result text. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item shift_match()

Shift and return an element off the match list. On error an exception C<Error::Simple> is thrown.

=item unshift_match(ARRAY)

Unshift additional values on the match list. C<ARRAY> is the list value. On error an exception C<Error::Simple> is thrown.

=over

=item The values in C<ARRAY> must be a (sub)class of:

=over

=item InfoSys::FreeDB::Match

=back

=back

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
Last update: December 2003

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

sub new_from_content_ref {
    my $class = shift;
    my $content_ref = shift;

    # Convert $opt->{content_ref} to @content_ref
    my @content_ref = split(/[\n\r]+/, ${$content_ref} );

    # Parse first line
    my $line = shift(@content_ref);
    my ($code, $tail) = $line =~ /$CODE_RX/;
    defined ($code) ||
        throw Error::Simple ('ERROR: InfoSys::FreeDB::Response::Query::new_from_content_ref, first line of specified \'content_ref\' does not contain a code.');
    my %opt;
    if ($code == 200) {
        my @tail = split(/\s+/, $tail, 3);
        require InfoSys::FreeDB::Match;
        %opt = (
            code => $code,
            exact_match => 1,
            result => 'Found exact match',
            match => [ InfoSys::FreeDB::Match->new( {
                categ => $tail[0],
                discid => $tail[1],
                dtitle => $tail[2],
            } ) ],
        );
    }
    elsif ($code == 210) {
        pop(@content_ref);
        my @match = ();
        foreach my $line (@content_ref) {
            my @line = split(/\s+/, $line, 3);
            require InfoSys::FreeDB::Match;
            push(@match, InfoSys::FreeDB::Match->new( {
                categ => $line[0],
                discid => $line[1],
                dtitle => $line[2],
            } ) );
        }
        %opt = (
            code => $code,
            result => 'Found exact matches',
            match => \@match,
        );
    }
    elsif ($code == 211) {
        pop(@content_ref);
        my @match = ();
        foreach my $line (@content_ref) {
            my @line = split(/\s+/, $line, 3);
            require InfoSys::FreeDB::Match;
            push(@match, InfoSys::FreeDB::Match->new( {
                categ => $line[0],
                discid => $line[1],
                dtitle => $line[2],
            } ) );
        }
        %opt = (
            code => $code,
            result => 'Found inexact matches',
            match => \@match,
        );
    }
    elsif ($code == 202) {
        %opt = (
            code => $code,
            result => 'No match found',
        );
    }
    elsif ($code == 403) {
        %opt = (
            code => $code,
            error => 1,
            result => 'Database entry is corrupt',
        );
    }
    elsif ($code == 409) {
        %opt = (
            code => $code,
            error => 1,
            result => 'No handshake',
        );
    }
    else {
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Response::Query::new_from_content_ref, unknown code '$code' returned. Allowed codes are 200, 210, 211, 202, 403 and 409.");
    }

    # Create a new object and return it
    return( $class->new( \%opt ) );
}

sub _initialize {
    my $self = shift;
    my $opt = defined($_[0]) ? shift : {};

    # Check $opt
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Query::_initialize, first argument must be 'HASH' reference.");

    # exact_match, BOOLEAN
    exists( $opt->{exact_match} ) && $self->set_exact_match( $opt->{exact_match} );

    # match, MULTI
    if ( exists( $opt->{match} ) ) {
        ref( $opt->{match} ) eq 'ARRAY' || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Query::_initialize, specified value for option 'match' must be an 'ARRAY' reference.");
        $self->set_match( @{ $opt->{match} } );
    }
    else {
        $self->set_match();
    }

    # Call the superclass' _initialize
    $self->SUPER::_initialize($opt);

    # Return $self
    return($self);
}

sub _value_is_allowed {
    my $name = shift;

    # Value is allowed if no ALLOW clauses exist for the named attribute
    if ( ! exists( $ALLOW_ISA{$name} ) && ! exists( $ALLOW_REF{$name} ) && ! exists( $ALLOW_RX{$name} ) && ! exists( $ALLOW_VALUE{$name} ) ) {
        return(1);
    }

    # At this point, all values in @_ must to be allowed
    CHECK_VALUES:
    foreach my $val (@_) {
        # Check ALLOW_ISA
        if ( ref($val) && exists( $ALLOW_ISA{$name} ) ) {
            foreach my $class ( @{ $ALLOW_ISA{$name} } ) {
                &UNIVERSAL::isa( $val, $class ) && next CHECK_VALUES;
            }
        }

        # Check ALLOW_REF
        if ( ref($val) && exists( $ALLOW_REF{$name} ) ) {
            exists( $ALLOW_REF{$name}{ ref($val) } ) && next CHECK_VALUES;
        }

        # Check ALLOW_RX
        if ( defined($val) && ! ref($val) && exists( $ALLOW_RX{$name} ) ) {
            foreach my $rx ( @{ $ALLOW_RX{$name} } ) {
                $val =~ /$rx/ && next CHECK_VALUES;
            }
        }

        # Check ALLOW_VALUE
        if ( ! ref($val) && exists( $ALLOW_VALUE{$name} ) ) {
            exists( $ALLOW_VALUE{$name}{$val} ) && next CHECK_VALUES;
        }

        # We caught a not allowed value
        return(0);
    }

    # OK, all values are allowed
    return(1);
}

sub exists_match {
    my $self = shift;

    # Count occurrences
    my $count = 0;
    foreach my $val1 (@_) {
        foreach my $val2 ( @{ $self->{InfoSys_FreeDB_Response_Query}{match} } ) {
            ( $val1 eq $val2 ) && $count ++;
        }
    }
    return($count);
}

sub get_match {
    my $self = shift;

    if ( scalar(@_) ) {
        my @ret = ();
        foreach my $i (@_) {
            push( @ret, $self->{InfoSys_FreeDB_Response_Query}{match}[ int($i) ] );
        }
        return(@ret);
    }
    else {
        # Return the full list
        return( @{ $self->{InfoSys_FreeDB_Response_Query}{match} } );
    }
}

sub is_exact_match {
    my $self = shift;

    if ( $self->{InfoSys_FreeDB_Response_Query}{exact_match} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub pop_match {
    my $self = shift;

    # Pop an element from the list
    return( pop( @{ $self->{InfoSys_FreeDB_Response_Query}{match} } ) );
}

sub push_match {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'match', @_ ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Query::push_match, one or more specified value(s) '@_' is/are not allowed.");

    # Push the list
    push( @{ $self->{InfoSys_FreeDB_Response_Query}{match} }, @_ );
}

sub set_exact_match {
    my $self = shift;

    if (shift) {
        $self->{InfoSys_FreeDB_Response_Query}{exact_match} = 1;
    }
    else {
        $self->{InfoSys_FreeDB_Response_Query}{exact_match} = 0;
    }
}

sub set_idx_match {
    my $self = shift;
    my $idx = shift;
    my $val = shift;

    # Check if index is a positive integer or zero
    ( $idx == int($idx) ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Query::set_idx_match, the specified index '$idx' is not an integer.");
    ( $idx >= 0 ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Query::set_idx_match, the specified index '$idx' is not a positive integer or zero.");

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'match', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Query::set_idx_match, one or more specified value(s) '@_' is/are not allowed.");

    # Set the value in the list
    $self->{InfoSys_FreeDB_Response_Query}{match}[$idx] = $val;
}

sub set_match {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'match', @_ ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Query::set_match, one or more specified value(s) '@_' is/are not allowed.");

    # Set the list
    @{ $self->{InfoSys_FreeDB_Response_Query}{match} } = @_;
}

sub set_num_match {
    my $self = shift;
    my $num = shift;

    # Check if index is an integer
    ( $num == int($num) ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Query::set_num_match, the specified number '$num' is not an integer.");

    # Call set_idx_match
    $self->set_idx_match( $num - 1, @_ );
}

sub shift_match {
    my $self = shift;

    # Shift an element from the list
    return( shift( @{ $self->{InfoSys_FreeDB_Response_Query}{match} } ) );
}

sub unshift_match {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'match', @_ ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Query::unshift_match, one or more specified value(s) '@_' is/are not allowed.");

    # Unshift the list
    unshift( @{ $self->{InfoSys_FreeDB_Response_Query}{match} }, @_ );
}

