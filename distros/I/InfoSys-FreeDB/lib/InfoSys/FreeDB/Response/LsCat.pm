package InfoSys::FreeDB::Response::LsCat;

use 5.006;
use base qw( InfoSys::FreeDB::Response );
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);

# Package version
our ($VERSION) = '$Revision: 0.92 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

InfoSys::FreeDB::Response::LsCat - FreeDB lscat response

=head1 SYNOPSIS

 require InfoSys::FreeDB;
 
 # Create a HTTP connection
 my $fact = InfoSys::FreeDB->new();
 my $conn = $fact->create_connection( {
     client_name => 'testing-InfoSys::FreeDB',
     client_version => $InfoSys::FreeDB::VERSION,
 } );
 
 # Get lscat from FreeDB
 my $res = $conn->lscat();
 
 # Write the categories to STDERR
 use IO::Handle;
 my $fh = IO::Handle->new_from_fd( fileno(STDERR), 'w' );
 foreach my $cat ( $res->get_category() ) {
     $fh->print( "$cat\n" );
 }

=head1 ABSTRACT

FreeDB lscat response

=head1 DESCRIPTION

C<InfoSys::FreeDB::Response::LsCat> contains information about FreeDB lscat responses.

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<InfoSys::FreeDB::Response::LsCat> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<category>>

Passed to L<set_category()>. Must be an C<ARRAY> reference.

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

Creates a new C<InfoSys::FreeDB::Response::LsCat> object from the specified content reference. C<CONTENT_REF> is a string reference. On error an exception C<Error::Simple> is thrown.

=back

=head1 METHODS

=over

=item exists_category(ARRAY)

Returns the count of items in C<ARRAY> that are in the category list.

=item get_category( [ INDEX_ARRAY ] )

Returns an C<ARRAY> containing the category list. C<INDEX_ARRAY> is an optional list of indexes which when specified causes only the indexed elements in the ordered list to be returned. If not specified, all elements are returned.

=item get_code()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns the response code.

=item get_result()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns the response result text.

=item is_error()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns whether the response has an error or not.

=item pop_category()

Pop and return an element off the category list. On error an exception C<Error::Simple> is thrown.

=item push_category(ARRAY)

Push additional values on the category list. C<ARRAY> is the list value. On error an exception C<Error::Simple> is thrown.

=item set_category(ARRAY)

Set the category list absolutely. C<ARRAY> is the list value. On error an exception C<Error::Simple> is thrown.

=item set_code(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. Set the response code. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_error(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. State that the response has an error. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_idx_category( INDEX, VALUE )

Set value in the category list. C<INDEX> is the integer index which is greater than or equal to C<0>. C<VALUE> is the value.

=item set_num_category( NUMBER, VALUE )

Set value in the category list. C<NUMBER> is the integer index which is greater than C<0>. C<VALUE> is the value.

=item set_result(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. Set the response result text. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item shift_category()

Shift and return an element off the category list. On error an exception C<Error::Simple> is thrown.

=item unshift_category(ARRAY)

Unshift additional values on the category list. C<ARRAY> is the list value. On error an exception C<Error::Simple> is thrown.

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
    my ($code) = $line =~ /^\s*(\d{3})\s+/;
    defined ($code) ||
        throw Error::Simple ('ERROR: InfoSys::FreeDB::Response::LsCat::new_from_content_ref, first line of specified \'content_ref\' does not contain a code.');
    my %opt;
    if ($code == 210) {
        pop(@content_ref);
        %opt = (
            code => $code,
            result => 'Okay',
            category => [ @content_ref ],
        );
    }
    else {
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Response::LsCat::new_from_content_ref, unknown code '$code' returned. Allowed code is 210.");
    }

    # Create a new object and return it
    return( $class->new( \%opt ) );
}

sub _initialize {
    my $self = shift;
    my $opt = defined($_[0]) ? shift : {};

    # Check $opt
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::LsCat::_initialize, first argument must be 'HASH' reference.");

    # category, MULTI
    if ( exists( $opt->{category} ) ) {
        ref( $opt->{category} ) eq 'ARRAY' || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::LsCat::_initialize, specified value for option 'category' must be an 'ARRAY' reference.");
        $self->set_category( @{ $opt->{category} } );
    }
    else {
        $self->set_category();
    }

    # Call the superclass' _initialize
    $self->SUPER::_initialize($opt);

    # Return $self
    return($self);
}

sub _value_is_allowed {
    return(1);
}

sub exists_category {
    my $self = shift;

    # Count occurrences
    my $count = 0;
    foreach my $val1 (@_) {
        foreach my $val2 ( @{ $self->{InfoSys_FreeDB_Response_LsCat}{category} } ) {
            ( $val1 eq $val2 ) && $count ++;
        }
    }
    return($count);
}

sub get_category {
    my $self = shift;

    if ( scalar(@_) ) {
        my @ret = ();
        foreach my $i (@_) {
            push( @ret, $self->{InfoSys_FreeDB_Response_LsCat}{category}[ int($i) ] );
        }
        return(@ret);
    }
    else {
        # Return the full list
        return( @{ $self->{InfoSys_FreeDB_Response_LsCat}{category} } );
    }
}

sub pop_category {
    my $self = shift;

    # Pop an element from the list
    return( pop( @{ $self->{InfoSys_FreeDB_Response_LsCat}{category} } ) );
}

sub push_category {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'category', @_ ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::LsCat::push_category, one or more specified value(s) '@_' is/are not allowed.");

    # Push the list
    push( @{ $self->{InfoSys_FreeDB_Response_LsCat}{category} }, @_ );
}

sub set_category {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'category', @_ ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::LsCat::set_category, one or more specified value(s) '@_' is/are not allowed.");

    # Set the list
    @{ $self->{InfoSys_FreeDB_Response_LsCat}{category} } = @_;
}

sub set_idx_category {
    my $self = shift;
    my $idx = shift;
    my $val = shift;

    # Check if index is a positive integer or zero
    ( $idx == int($idx) ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::LsCat::set_idx_category, the specified index '$idx' is not an integer.");
    ( $idx >= 0 ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::LsCat::set_idx_category, the specified index '$idx' is not a positive integer or zero.");

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'category', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::LsCat::set_idx_category, one or more specified value(s) '@_' is/are not allowed.");

    # Set the value in the list
    $self->{InfoSys_FreeDB_Response_LsCat}{category}[$idx] = $val;
}

sub set_num_category {
    my $self = shift;
    my $num = shift;

    # Check if index is an integer
    ( $num == int($num) ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::LsCat::set_num_category, the specified number '$num' is not an integer.");

    # Call set_idx_category
    $self->set_idx_category( $num - 1, @_ );
}

sub shift_category {
    my $self = shift;

    # Shift an element from the list
    return( shift( @{ $self->{InfoSys_FreeDB_Response_LsCat}{category} } ) );
}

sub unshift_category {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'category', @_ ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::LsCat::unshift_category, one or more specified value(s) '@_' is/are not allowed.");

    # Unshift the list
    unshift( @{ $self->{InfoSys_FreeDB_Response_LsCat}{category} }, @_ );
}

