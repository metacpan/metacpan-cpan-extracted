package Eidolon::Driver::DB::Exceptions;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Driver/DB/Exceptions.pm - database driver exceptions
#
# ==============================================================================

use warnings;
use strict;

our $VERSION = "0.02"; # 2009-05-14 05:36:22

use Eidolon::Core::Exception::Builder 
(
    "DriverError::DB" => 
    {
        "isa"   => "DriverError",
        "title" => "Database driver error"
    },

    "DriverError::DB::Connect" => 
    {
        "isa"   => "DriverError::DB",
        "title" => "Database connect error"
    },

    "DriverError::DB::SQL" => 
    {
        "isa"   => "DriverError::DB",
        "title" => "SQL query error"
    },

    "DriverError::DB::AlreadyFetched" =>
    {
        "isa"   => "DriverError::DB",
        "title" => "Data is already fetched during query execution (auto_fetch option is on)"
    }
);

1;

__END__

=head1 NAME

Eidolon::Driver::DB::Exceptions - Eidolon database driver exceptions.

=head1 SYNOPSIS

In error handler of your application (C<lib/Example/Error.pm>) you could write:

    if ($e eq "DriverError::DB::SQL")
    {
        print "You have an error in your SQL syntax!";
    }
    else
    {
        $e->rethrow();
    }

=head1 DESCRIPTION

The I<Eidolon::Driver::DB::Exceptions> package creates database driver exceptions
that are used by all database drivers.

=head1 EXCEPTIONS

=head2 Error::Driver::DB

Base database driver exception. All other database driver exceptions subclass 
it.

=head2 Error::Driver::DB::Connect

Database connection error. Thrown when driver cannot connect or login to 
database engine.

=head2 Error::Driver::DB::SQL

Database SQL execution error. Thrown in case of invalid SQL command.

=head1 SEE ALSO

L<Eidolon>, L<Eidolon::Driver::Exceptions>,
L<Eidolon::Core::Exception>,
L<Eidolon::Core::Exception::Builder>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut

