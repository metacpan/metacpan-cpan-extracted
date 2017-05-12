package Gantry::Utils::DBConnHelper;
use strict; use warnings;

use Carp;

my $subclass;

sub import {
    my $class     = shift;
    my $conn_info = shift || return;

    $class->set_conn_info( $conn_info );
}

sub set_subclass {
    my $class = shift;
    $subclass = shift;
}

sub get_subclass {
    return $subclass;
}

1;

=head1 NAME

Gantry::Utils::DBConnHelper - connection info and dbh cache manager base module

=head1 SYNOPSIS

    package Gantry::Utils::DBConnHelper::YourHelper;

    use base 'Gantry::Utils::DBConnHelper';

    Gantry::Utils::DBConnHelper->set_subclass(
        'Gantry::Utils::DBConnHelper::YourHelper'
    );

    sub get_dbh            {...}
    sub set_dbh            {...}
    sub get_conn_info      {...}
    sub set_conn_info      {...}  # only for some helpers
    sub get_auth_dbh       {...}
    sub set_auth_dbh       {...}
    sub get_auth_conn_info {...}
    sub set_auth_conn_info {...}  # only for some helpers

=head1 DESCRIPTION

This is mostly a documentation module.  You should probably use one of the
available implementing modules like Gantry::Utils::DBConnHelper::Script,
Gantry::Utils::DBConnHelper::MP13, etc.  If none of those fit your needs
you need to subclass this modules and define all of the methods listed below
(see the synopsis for an example).  If you choose to subclass, you will
inherit the import method from this module.  It allows your callers to pass
a hash reference of database connection info in their use statement, instead
of calling set_conn_info.  This only works for the Script helper.

=head1 METHODS of this class

=over 4

=item set_subclass

Your subclass MUST call this method at compile time passing in the
fully qualified name of your subclass.

=item get_subclass

Returns the name of the subclass providing the actual connection information.
Used by any one that wants to ask the subclass for connection info.  The
prime example is Gantry::Utils::ModelHelper.

=back

=head1 Required METHODS

Your module needs to implement the methods below.  Failure to implement them
will likely result in a fatal error at run time (or difficult to track
bugs).

Get methods don't receive any parameters other than the invocant.

=over 4

=item get_dbh

(required by Gantry::Utils::CDBI and Gantry::Utils::Model)

Return a valid dbh if you have one or undef if not.

=item set_dbh

(required by Gantry::Utils::CDBI and Gantry::Utils::Model)

Receives a dbh which it should store in its cache.

=item get_conn_info

(required by Gantry::Utils::CDBI and Gantry::Utils::Model)

Returns a hash reference of connection info with these keys:

=over 4

=item dbconn

a full dsn suitable for passing directly to DBI's connect method

=item dbuser

the name of the database user

=item dbpass

the password for dbuser

=back

Other keys in the hash are ignored.

=back

=head1 Optional METHODS (Required for Gantry authentication)

In addition to connecting to an application database, Gantry can provide
authentication.  In that case it uses a separate connection to the app's
auth database.  This enables it to share authentication databases across
apps.

Note that there is nothing that prevents you from storing the auth info
in the same database as the app data.  We just use two connections to
add the flexibility to split these.  In any case, if you are using
Gantry auth, you must use the methods below.

(Note the symmetry between these methods and the ones above.  These
simply have auth_ inserted into their names.)

=over 4

=item get_auth_dbh

(required by Gantry::Utils::AuthCDBI and Gantry::Utils::AuthModel)

Returns the database handle for the authentication database.

=item set_auth_dbh

(required by Gantry::Utils::AuthCDBI and Gantry::Utils::AuthModel)

Receives a database handle for the authentication database which it
should cache for later retrieval by get_auth_dbh.

=item get_auth_conn_info

(required by Gantry::Utils::AuthCDBI and Gantry::Utils::AuthModel)

Returns a hash reference of connection info with these keys:

=over 4

=item auth_dbconn

a full dsn suitable for passing directly to DBI's connect method

=item auth_dbuser

the name of the database user

=item auth_dbpass

the password for dbuser

=back

Other keys in the hash are ignored.

It is perfectly reasonable to use the same database -- or even database handle
-- for both the auth and regular connections.  But, you need to provide
the methods above so that Gantry can find them.

=back

=head1 A METHOD for SUBCLASSES

This module does supply a useful import method which you can inherit.
It allows users to supply the connection information hash as a parameter
in their use statement like this:

    use Gantry::Utils::DBConnHelper::YourSubclass {
        dbconn = 'dbi:Pg:dbname=mydb;host=127.0.0.1',
        dbuser = 'someuser',
        dbpass = 'not_saying',
    };

The caller has the option of doing this in two steps (in case they need
to calculate the connection information at run time):

    use Gantry::Utils::DBConnHelper::YourSubclass;

    # ... figure out what information to provide

    Gantry::Utils::DBConnHelper::YourSubclass->set_conn_info(
        {
            dbconn = $dsn,
            dbuser = $user,
            dbpass = $pass,
        }
    );

The import method does not help with authentication connection info.

=head1 OTHER METHODS

Gantry::Util::DBConnHelper::Script has two other methods for use by
scripts, constructors, init methods or the like.

=over 4

=item set_conn_info

Not implemented by mod_perl helpers.

Receives a hash of connection information suitable for use as the return
value of get_conn_info.

=item set_auth_conn_info

Not implemented by mod_perl helpers.

Receives a hash reference of connection info which it should store for
later retrieval via get_conn_info.

=back

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2005-6, Phil Crow.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
