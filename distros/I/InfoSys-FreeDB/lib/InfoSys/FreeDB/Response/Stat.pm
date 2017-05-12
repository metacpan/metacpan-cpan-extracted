package InfoSys::FreeDB::Response::Stat;

use 5.006;
use base qw( InfoSys::FreeDB::Response );
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);

our $STAT_DB_ENTRIES_RX = '^\s*database\s+entries\s*:\s*(\S+)';

our $STAT_GETS_RX = '^\s*gets\s*:\s*(\S+)';

our $STAT_POSTING_RX = '^\s*posting\s*:\s*(\S+)';

our $STAT_PROTO_CUR_RX = '^\s*current\s+proto\s*:\s*(\S+)';

our $STAT_PROTO_MAX_RX = '^\s*max\s+proto\s*:\s*(\S+)';

our $STAT_QUOTES_RX = '^\s*quotes\s*:\s*(\S+)';

our $STAT_STRIP_EXT = '^\s*strip\s+ext\s*:\s*(\S+)';

our $STAT_UPDATES_RX = '^\s*updates\s*:\s*(\S+)';

our $STAT_USERS_CUR_RX = '^\s*current\s+users\s*:\s*(\S+)';

our $STAT_USERS_MAX_RX = '^\s*max\s+users\s*:\s*(\S+)';

# Package version
our ($VERSION) = '$Revision: 0.92 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

InfoSys::FreeDB::Response::Stat - FreeDB stat response

=head1 SYNOPSIS

 require InfoSys::FreeDB;
 
 # Create a HTTP connection
 my $fact = InfoSys::FreeDB->new();
 my $conn = $fact->create_connection( {
     client_name => 'testing-InfoSys::FreeDB',
     client_version => $InfoSys::FreeDB::VERSION,
 } );
 
 # Get stat from FreeDB
 my $res = $conn->stat();
 
 # Write a bit of stat to STDERR
 use IO::Handle;
 my $fh = IO::Handle->new_from_fd( fileno(STDERR), 'w' );
 $fh->print( "\n", $res->get_proto_cur(), "\n" );

=head1 ABSTRACT

FreeDB stat response

=head1 DESCRIPTION

C<InfoSys::FreeDB::Response::Stat> contains information about FreeDB stat responses.

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<InfoSys::FreeDB::Response::Stat> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<database_entries>>

Passed to L<set_database_entries()>.

=item B<C<gets>>

Passed to L<set_gets()>.

=item B<C<posting>>

Passed to L<set_posting()>.

=item B<C<proto_cur>>

Passed to L<set_proto_cur()>.

=item B<C<proto_max>>

Passed to L<set_proto_max()>.

=item B<C<quotes>>

Passed to L<set_quotes()>.

=item B<C<strip_ext>>

Passed to L<set_strip_ext()>.

=item B<C<updates>>

Passed to L<set_updates()>.

=item B<C<users_cur>>

Passed to L<set_users_cur()>.

=item B<C<users_max>>

Passed to L<set_users_max()>.

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

Creates a new C<InfoSys::FreeDB::Response::Stat> object from the specified content reference. C<CONTENT_REF> is a string reference. On error an exception C<Error::Simple> is thrown.

=back

=head1 METHODS

=over

=item get_code()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns the response code.

=item get_database_entries()

Returns the total number of entries in the database.

=item get_proto_cur()

Returns the server's current operating protocol level.

=item get_proto_max()

Returns the maximum supported protocol level.

=item get_result()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns the response result text.

=item get_users_cur()

Returns the number of users currently connected to the server.

=item get_users_max()

Returns the number of users that can concurrently connect to the server.

=item is_error()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns whether the response has an error or not.

=item is_gets()

Returns whether the client is allowed to get log information or not.

=item is_posting()

Returns whether the client is allowed to post new entries or not.

=item is_quotes()

Returns whether the quoted arguments are enabled or not.

=item is_strip_ext()

Returns whether the extended data is stripped by the server before presented to the user or not.

=item is_updates()

Returns whether the client is allowed to initiate a database update or not.

=item set_code(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. Set the response code. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_database_entries(VALUE)

Set the total number of entries in the database. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_error(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. State that the response has an error. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_gets(VALUE)

State that the client is allowed to get log information. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_posting(VALUE)

State that the client is allowed to post new entries. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_proto_cur(VALUE)

Set the server's current operating protocol level. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_proto_max(VALUE)

Set the maximum supported protocol level. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_quotes(VALUE)

State that the quoted arguments are enabled. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_result(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. Set the response result text. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_strip_ext(VALUE)

State that the extended data is stripped by the server before presented to the user. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_updates(VALUE)

State that the client is allowed to initiate a database update. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_users_cur(VALUE)

Set the number of users currently connected to the server. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_users_max(VALUE)

Set the number of users that can concurrently connect to the server. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

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
    my ($code) = $line =~ /^\s*(\d{3})\s/;
    defined ($code) ||
        throw Error::Simple ('ERROR: InfoSys::FreeDB::Response::Stat::new_from_content_ref, first line of specified \'content_ref\' does not contain a code.');
    my %opt;
    if ($code == 210) {
        pop(@content_ref);
        %opt = (
            code => $code,
            result => 'Ok',
            message_text => join("\n", @content_ref),
        );

        foreach my $line (@content_ref) {
            my $val;
            if ( ($val) = $line =~ /$STAT_DB_ENTRIES_RX/i ) {
                $opt{database_entries} = $val;
                last;
            }
            elsif ( ($val) = $line =~ /$STAT_GETS_RX/i ) {
                $opt{gets} = $val =~ /yes/i;
                next;
            }
            elsif ( ($val) = $line =~ /$STAT_POSTING_RX/i ) {
                $opt{posting} = $val =~ /yes/i;
                next;
            }
            elsif ( ($val) = $line =~ /$STAT_PROTO_CUR_RX/i ) {
                $opt{proto_cur} = $val;
                next;
            }
            elsif ( ($val) = $line =~ /$STAT_PROTO_MAX_RX/i ) {
                $opt{proto_max} = $val;
                next;
            }
            elsif ( ($val) = $line =~ /$STAT_QUOTES_RX/i ) {
                $opt{quotes} = $val =~ /yes/i;
                next;
            }
            elsif ( ($val) = $line =~ /$STAT_STRIP_EXT/i ) {
                $opt{strip_ext} = $val =~ /yes/i;
                next;
            }
            elsif ( ($val) = $line =~ /$STAT_USERS_CUR_RX/i ) {
                $opt{users_cur} = $val;
                next;
            }
            elsif ( ($val) = $line =~ /$STAT_USERS_MAX_RX/i ) {
                $opt{users_max} = $val;
                next;
            }
        }
    }
    else {
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Response::Stat::new_from_content_ref, unknown code '$code' returned. Allowed code is 210.");
    }

    # Create a new object and return it
    return( $class->new( \%opt ) );
}

sub _initialize {
    my $self = shift;
    my $opt = defined($_[0]) ? shift : {};

    # Check $opt
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Stat::_initialize, first argument must be 'HASH' reference.");

    # database_entries, SINGLE
    exists( $opt->{database_entries} ) && $self->set_database_entries( $opt->{database_entries} );

    # gets, BOOLEAN
    exists( $opt->{gets} ) && $self->set_gets( $opt->{gets} );

    # posting, BOOLEAN
    exists( $opt->{posting} ) && $self->set_posting( $opt->{posting} );

    # proto_cur, SINGLE
    exists( $opt->{proto_cur} ) && $self->set_proto_cur( $opt->{proto_cur} );

    # proto_max, SINGLE
    exists( $opt->{proto_max} ) && $self->set_proto_max( $opt->{proto_max} );

    # quotes, BOOLEAN
    exists( $opt->{quotes} ) && $self->set_quotes( $opt->{quotes} );

    # strip_ext, BOOLEAN
    exists( $opt->{strip_ext} ) && $self->set_strip_ext( $opt->{strip_ext} );

    # updates, BOOLEAN
    exists( $opt->{updates} ) && $self->set_updates( $opt->{updates} );

    # users_cur, SINGLE
    exists( $opt->{users_cur} ) && $self->set_users_cur( $opt->{users_cur} );

    # users_max, SINGLE
    exists( $opt->{users_max} ) && $self->set_users_max( $opt->{users_max} );

    # Call the superclass' _initialize
    $self->SUPER::_initialize($opt);

    # Return $self
    return($self);
}

sub _value_is_allowed {
    return(1);
}

sub get_database_entries {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Response_Stat}{database_entries} );
}

sub get_proto_cur {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Response_Stat}{proto_cur} );
}

sub get_proto_max {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Response_Stat}{proto_max} );
}

sub get_users_cur {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Response_Stat}{users_cur} );
}

sub get_users_max {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Response_Stat}{users_max} );
}

sub is_gets {
    my $self = shift;

    if ( $self->{InfoSys_FreeDB_Response_Stat}{gets} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub is_posting {
    my $self = shift;

    if ( $self->{InfoSys_FreeDB_Response_Stat}{posting} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub is_quotes {
    my $self = shift;

    if ( $self->{InfoSys_FreeDB_Response_Stat}{quotes} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub is_strip_ext {
    my $self = shift;

    if ( $self->{InfoSys_FreeDB_Response_Stat}{strip_ext} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub is_updates {
    my $self = shift;

    if ( $self->{InfoSys_FreeDB_Response_Stat}{updates} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub set_database_entries {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'database_entries', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Stat::set_database_entries, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Response_Stat}{database_entries} = $val;
}

sub set_gets {
    my $self = shift;

    if (shift) {
        $self->{InfoSys_FreeDB_Response_Stat}{gets} = 1;
    }
    else {
        $self->{InfoSys_FreeDB_Response_Stat}{gets} = 0;
    }
}

sub set_posting {
    my $self = shift;

    if (shift) {
        $self->{InfoSys_FreeDB_Response_Stat}{posting} = 1;
    }
    else {
        $self->{InfoSys_FreeDB_Response_Stat}{posting} = 0;
    }
}

sub set_proto_cur {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'proto_cur', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Stat::set_proto_cur, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Response_Stat}{proto_cur} = $val;
}

sub set_proto_max {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'proto_max', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Stat::set_proto_max, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Response_Stat}{proto_max} = $val;
}

sub set_quotes {
    my $self = shift;

    if (shift) {
        $self->{InfoSys_FreeDB_Response_Stat}{quotes} = 1;
    }
    else {
        $self->{InfoSys_FreeDB_Response_Stat}{quotes} = 0;
    }
}

sub set_strip_ext {
    my $self = shift;

    if (shift) {
        $self->{InfoSys_FreeDB_Response_Stat}{strip_ext} = 1;
    }
    else {
        $self->{InfoSys_FreeDB_Response_Stat}{strip_ext} = 0;
    }
}

sub set_updates {
    my $self = shift;

    if (shift) {
        $self->{InfoSys_FreeDB_Response_Stat}{updates} = 1;
    }
    else {
        $self->{InfoSys_FreeDB_Response_Stat}{updates} = 0;
    }
}

sub set_users_cur {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'users_cur', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Stat::set_users_cur, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Response_Stat}{users_cur} = $val;
}

sub set_users_max {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'users_max', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Stat::set_users_max, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Response_Stat}{users_max} = $val;
}

