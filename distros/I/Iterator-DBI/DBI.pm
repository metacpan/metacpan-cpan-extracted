=for gpg
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA1

=head1 NAME

Iterator::DBI - An iterator for returning DBI query results.

=head1 VERSION

This documentation describes version 0.02 of Iterator::DBI, August 23, 2005.

=cut

use strict;
use warnings;
package Iterator::DBI;
our $VERSION = '0.02';

use base 'Exporter';
use vars qw/@EXPORT @EXPORT_OK %EXPORT_TAGS/;
@EXPORT  = qw(idb_rows);
@EXPORT_OK   = @EXPORT;

use Iterator;


# Function name: idb_rows
# Synopsis:      $iter = idb_rows ($dbh, $sql, @bind_vars);
# Description:   Iterates over a database query's results
# Created:       07/29/2005 by EJR
# Parameters:    $dbh - A DBI database handle
#                $sql - The query
#                @bind_vars - (optional) bind variables.
# Returns:       Row iterator (returns hash references)
# Exceptions:    Iterator::X::Parameter_Error
#                "idb_rows cannot prepare sql: <error string>"
#                "idb_rows cannot execute sql: <error string>"
#                "fetchrow_hashref: <error string>"
#                Iterator::X::Am_Now_Exhausted
sub idb_rows
{
    my ($dbh, $sql, @bind) = @_;
    my $sth;    # statement handle

    Iterator::X::Parameter_Error->throw
        ('idb_rows: $dbh parameter is not a database handle')
        unless UNIVERSAL::can($dbh, 'prepare');

    return Iterator->new (sub
    {
        # Prepare database statement, if not done alread
        unless ($sth)
        {
            $sth = $dbh->prepare($sql)
                or die "idb_rows cannot prepare sql: " . $dbh->errstr;

            unless ($sth->execute(@bind))
            {
                $sth->finish;
                undef $sth;     # allow garbage collection
                die "idb_rows cannot execute sql: " . $sth->errstr;
            }
        }

        # Fetch the row
        my $row_ref = $sth->fetchrow_hashref;

        # Check for errors
        if (!defined $row_ref)
        {
            if ($sth->err)
            {
                die "idb_rows: fetch error: " . $sth->errstr;
            }
            Iterator::is_done;
        }

        return $row_ref;
    });
}

1;
__END__

=head1 SYNOPSIS

 use Iterator::DBI;

 # Iterate over a database SELECT query.
 # (returns one hash reference per row).
 $iter = idb_rows ($dbh, $sql);
 $iter = idb_rows ($dbh, $sql, @bind);

=head1 DESCRIPTION

This module contains a function to return an iterator (see the
L<Iterator> module) that returns the rows of a database query, one at
a time.

This is marginally more useful than simply calling
L<prepare|DBI/prepare> and L<execute|DBI/execute>, and then repeatedly
calling L<fetchrow_hashref|DBI/fetchrow_hashref>; since this one
function bundles up the calls to all three of those DBI methods.

But the real usefulness of this interface is that it can be chained
together with other Iterator functions.  The L</idb_rows> iterator has
the same interface as any other interface, making it interchangeable
with iterators of any other source (for example, files), and usable
with the iterator manipulation functions in the L<Iterator::Util>
module.

=head1 FUNCTIONS

=over 4

=item idb_rows

 $it = idb_rows ($dbh, $sql);
 $it = idb_rows ($dbh, $sql, @bind);

Returns an iterator to return rows from a database query.  Each row is
returned as a hashref, as from C<fetchrow_hashref|DBI/fetchrow_hashref>
from the DBI module.

If the query requires bind variables, they may be passed in C<@bind>.

I<Example:>

 $dbh = DBI->connect (...);
 $iter = idb_rows ($dbh, 'select foo, bar from quux');
 $row_ref = $iter->value;

=back

=head1 EXPORTS

The following symbol is exported to the caller's namespace:

 idb_rows

=head1 DIAGNOSTICS

Iterator::DBI uses L<Exception::Class> objects for throwing exceptions.
If you're not familiar with Exception::Class, don't worry; these
exception objects work just like C<$@> does with C<die> and C<croak>,
but they are easier to work with if you are trapping errors.

You can learn more about Iterator exceptions in the
L<Iterator|Iterator/DIAGNOSTICS> module documentation.

=over 4

=item * Parameter Errors

Class: C<Iterator::X::Parameter_Error>

You called idb_rows with one or more bad parameters.  Since this is
almost certainly a coding error, there is probably not much use in
handling this sort of exception.

As a string, this exception provides a human-readable message about
what the problem was.

=item * Prepare error

String: "idb_rows cannot prepare sql: I<message>"

The DBI C<prepare> method returned an error.

=item * Execution error

String: "idb_rows cannot execute sql: I<message>"

The DBI C<execute> method returned an error.

=item * Fetch error

String: "idb_rows: fetch error: I<message>"

The DBI C<fetchrow_hashref> method returned an error.

=back

=head1 REQUIREMENTS

Requires the following additional modules:

L<Iterator>

L<DBI>

=head1 SEE ALSO

I<Higher Order Perl>, Mark Jason Dominus, Morgan Kauffman 2005.

L<http://perl.plover.com/hop/>

The L<Iterator> module.

The L<DBI> module.

=head1 AUTHOR / COPYRIGHT

Eric J. Roode, roode@cpan.org

Copyright (c) 2005 by Eric J. Roode.  All Rights Reserved.
This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

To avoid my spam filter, please include "Perl", "module", or this
module's name in the message's subject line, and/or GPG-sign your
message.

=cut

=begin gpg

-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1.4.1 (Cygwin)

iD8DBQFDC5R8Y96i4h5M0egRAtxIAJ9/FJ1TndC3JKlesiWUAred9JWW/wCcDVRA
dfUba0u3uWhaRP9zx3TaJEQ=
=jGbz
-----END PGP SIGNATURE-----

=end gpg
