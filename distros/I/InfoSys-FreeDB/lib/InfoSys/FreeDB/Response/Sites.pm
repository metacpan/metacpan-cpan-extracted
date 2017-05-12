package InfoSys::FreeDB::Response::Sites;

use 5.006;
use base qw( InfoSys::FreeDB::Response );
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);

# Used by _value_is_allowed
our %ALLOW_ISA = (
    'site' => [ 'InfoSys::FreeDB::Site' ],
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

InfoSys::FreeDB::Response::Sites - FreeDB sites response

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

FreeDB sites response

=head1 DESCRIPTION

C<InfoSys::FreeDB::Response::Sites> contains information about FreeDB sites responses.

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<InfoSys::FreeDB::Response::Sites> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<site>>

Passed to L<set_site()>. Must be an C<ARRAY> reference.

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

Creates a new C<InfoSys::FreeDB::Response::Sites> object from the specified content reference. C<CONTENT_REF> is a string reference. On error an exception C<Error::Simple> is thrown.

=back

=head1 METHODS

=over

=item exists_site(ARRAY)

Returns the count of items in C<ARRAY> that are in the site list.

=item get_code()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns the response code.

=item get_result()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns the response result text.

=item get_site( [ INDEX_ARRAY ] )

Returns an C<ARRAY> containing the site list. C<INDEX_ARRAY> is an optional list of indexes which when specified causes only the indexed elements in the ordered list to be returned. If not specified, all elements are returned.

=item is_error()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns whether the response has an error or not.

=item pop_site()

Pop and return an element off the site list. On error an exception C<Error::Simple> is thrown.

=item push_site(ARRAY)

Push additional values on the site list. C<ARRAY> is the list value. On error an exception C<Error::Simple> is thrown.

=over

=item The values in C<ARRAY> must be a (sub)class of:

=over

=item InfoSys::FreeDB::Site

=back

=back

=item set_code(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. Set the response code. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_error(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. State that the response has an error. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_idx_site( INDEX, VALUE )

Set value in the site list. C<INDEX> is the integer index which is greater than or equal to C<0>. C<VALUE> is the value.

=over

=item The values in C<ARRAY> must be a (sub)class of:

=over

=item InfoSys::FreeDB::Site

=back

=back

=item set_num_site( NUMBER, VALUE )

Set value in the site list. C<NUMBER> is the integer index which is greater than C<0>. C<VALUE> is the value.

=over

=item The values in C<ARRAY> must be a (sub)class of:

=over

=item InfoSys::FreeDB::Site

=back

=back

=item set_result(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. Set the response result text. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_site(ARRAY)

Set the site list absolutely. C<ARRAY> is the list value. On error an exception C<Error::Simple> is thrown.

=over

=item The values in C<ARRAY> must be a (sub)class of:

=over

=item InfoSys::FreeDB::Site

=back

=back

=item shift_site()

Shift and return an element off the site list. On error an exception C<Error::Simple> is thrown.

=item unshift_site(ARRAY)

Unshift additional values on the site list. C<ARRAY> is the list value. On error an exception C<Error::Simple> is thrown.

=over

=item The values in C<ARRAY> must be a (sub)class of:

=over

=item InfoSys::FreeDB::Site

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
L<InfoSys::FreeDB::Response::Query>,
L<InfoSys::FreeDB::Response::Quit>,
L<InfoSys::FreeDB::Response::Read>,
L<InfoSys::FreeDB::Response::SignOn>,
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
        throw Error::Simple ('ERROR: InfoSys::FreeDB::Response::Sites::new_from_content_ref, first line of specified \'content_ref\' does not contain a code.');
    my %opt;
    if ($code == 210) {
        pop(@content_ref);
        my @site = ();
        foreach my $line (@content_ref) {
            my ($site, $port_proto, $tail) = split(/\s+/, $line, 3);
            require InfoSys::FreeDB::Site;
            if ( $port_proto =~ /^\d+$/ ) {
                my @line = split(/\s+/, $tail, 3);
                push( @site, InfoSys::FreeDB::Site->new( {
                    site => $site,
                    protocol => 'cddbp',
                    port => $port_proto,
                    latitude => $line[0],
                    longitude => $line[1],
                    description => $line[2],
                } ) );
            }
            else {
                my @line = split(/\s+/, $tail, 5);
                push( @site, InfoSys::FreeDB::Site->new( {
                    site => $site,
                    protocol => $port_proto,
                    port => $line[0],
                    address => $line[1],
                    latitude => $line[2],
                    longitude => $line[3],
                    description => $line[4],
                } ) );
            }
        }
        %opt = (
            code => $code,
            result => 'Ok',
            site => \@site,
        );
    }
    elsif ($code == 401) {
        %opt = (
            code => $code,
            result => 'No site information available',
        );
    }
    else {
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Response::Sites::new_from_content_ref, unknown code '$code' returned. Allowed codes are 210 and 401.");
    }

    # Create a new object and return it
    return( $class->new( \%opt ) );
}

sub _initialize {
    my $self = shift;
    my $opt = defined($_[0]) ? shift : {};

    # Check $opt
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Sites::_initialize, first argument must be 'HASH' reference.");

    # site, MULTI
    if ( exists( $opt->{site} ) ) {
        ref( $opt->{site} ) eq 'ARRAY' || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Sites::_initialize, specified value for option 'site' must be an 'ARRAY' reference.");
        $self->set_site( @{ $opt->{site} } );
    }
    else {
        $self->set_site();
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

sub exists_site {
    my $self = shift;

    # Count occurrences
    my $count = 0;
    foreach my $val1 (@_) {
        foreach my $val2 ( @{ $self->{InfoSys_FreeDB_Response_Sites}{site} } ) {
            ( $val1 eq $val2 ) && $count ++;
        }
    }
    return($count);
}

sub get_site {
    my $self = shift;

    if ( scalar(@_) ) {
        my @ret = ();
        foreach my $i (@_) {
            push( @ret, $self->{InfoSys_FreeDB_Response_Sites}{site}[ int($i) ] );
        }
        return(@ret);
    }
    else {
        # Return the full list
        return( @{ $self->{InfoSys_FreeDB_Response_Sites}{site} } );
    }
}

sub pop_site {
    my $self = shift;

    # Pop an element from the list
    return( pop( @{ $self->{InfoSys_FreeDB_Response_Sites}{site} } ) );
}

sub push_site {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'site', @_ ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Sites::push_site, one or more specified value(s) '@_' is/are not allowed.");

    # Push the list
    push( @{ $self->{InfoSys_FreeDB_Response_Sites}{site} }, @_ );
}

sub set_idx_site {
    my $self = shift;
    my $idx = shift;
    my $val = shift;

    # Check if index is a positive integer or zero
    ( $idx == int($idx) ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Sites::set_idx_site, the specified index '$idx' is not an integer.");
    ( $idx >= 0 ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Sites::set_idx_site, the specified index '$idx' is not a positive integer or zero.");

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'site', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Sites::set_idx_site, one or more specified value(s) '@_' is/are not allowed.");

    # Set the value in the list
    $self->{InfoSys_FreeDB_Response_Sites}{site}[$idx] = $val;
}

sub set_num_site {
    my $self = shift;
    my $num = shift;

    # Check if index is an integer
    ( $num == int($num) ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Sites::set_num_site, the specified number '$num' is not an integer.");

    # Call set_idx_site
    $self->set_idx_site( $num - 1, @_ );
}

sub set_site {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'site', @_ ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Sites::set_site, one or more specified value(s) '@_' is/are not allowed.");

    # Set the list
    @{ $self->{InfoSys_FreeDB_Response_Sites}{site} } = @_;
}

sub shift_site {
    my $self = shift;

    # Shift an element from the list
    return( shift( @{ $self->{InfoSys_FreeDB_Response_Sites}{site} } ) );
}

sub unshift_site {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'site', @_ ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Sites::unshift_site, one or more specified value(s) '@_' is/are not allowed.");

    # Unshift the list
    unshift( @{ $self->{InfoSys_FreeDB_Response_Sites}{site} }, @_ );
}

