package Eidolon::Driver::Router::Exceptions;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Driver/Router/Exceptions.pm - router driver exceptions
#
# ==============================================================================

use warnings;
use strict;

our $VERSION = "0.02"; # 2009-05-14 05:44:39

use Eidolon::Core::Exception::Builder 
(
    "DriverError::Router" => 
    {
        "isa"   => "DriverError",
        "title" => "Router driver error"
    },

    "DriverError::Router::NotFound" => 
    {
        "isa"   => "DriverError::Router",
        "title" => "Page not found"
    },

    "DriverError::Router::Forbidden" => 
    {
        "isa"   => "DriverError::Router",
        "title" => "Authorization required"
    },

    "DriverError::Router::NoRoutes" =>
    {
        "isa"   => "DriverError::Router",
        "title" => "No routes defined for the application"
    }
);

1;

__END__

=head1 NAME

Eidolon::Driver::Router::Exceptions - Eidolon router driver exceptions.

=head1 SYNOPSIS

In error handler of your application (C<lib/Example/Error.pm>) you could write:

    if ($e eq "Error::Driver::Router::NotFound")
    {
        print "Page not found!";
    }
    else
    {
        $e->rethrow();
    }

=head1 DESCRIPTION

The I<Eidolon::Driver::Router::Exceptions> package creates router driver 
exceptions that are used by all router drivers.

=head1 EXCEPTIONS

=head2 Error::Driver::Router

Base router driver exception. All other router driver exceptions subclass it.

=head2 Error::Driver::Router::NotFound

Nothing was found during a query handler search.

=head2 Error::Driver::Router::Forbidden

Current user has no permissions to view this page. For example, the application
(or the page) is private and user is not authorized.

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
