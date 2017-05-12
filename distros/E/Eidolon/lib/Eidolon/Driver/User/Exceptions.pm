package Eidolon::Driver::User::Exceptions;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Driver/User/Exceptions.pm - user driver exceptions
#
# ==============================================================================

use warnings;
use strict;

our $VERSION = "0.02"; # 2009-05-14 05:46:01

use Eidolon::Core::Exception::Builder 
(
    "DriverError::User" => 
    {
        "isa"   => "DriverError",
        "title" => "User driver exceptions"
    }
);

1;

__END__

=head1 NAME

Eidolon::Driver::User::Exceptions - Eidolon user driver exceptions.

=head1 SYNOPSIS

In error handler of your application (C<lib/Example/Error.pm>) you
could write:

    if ($e eq "Error::Driver::User")
    {
        print "User driver failed!";
    }
    else
    {
        $e->rethrow();
    }

=head1 DESCRIPTION

The I<Eidolon::Driver::User::Exceptions> package creates user driver 
exceptions that are used by all user drivers.

=head1 EXCEPTIONS

=head2 Error::Driver::User

Base user driver exception. All other user driver exceptions subclass it.

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
