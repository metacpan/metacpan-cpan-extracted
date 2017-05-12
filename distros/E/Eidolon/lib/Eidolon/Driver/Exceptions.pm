package Eidolon::Driver::Exceptions;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Driver/Exceptions.pm - driver exceptions
#
# ==============================================================================

use warnings;
use strict;

our $VERSION = "0.02"; # 2009-05-14 05:20:08

use Eidolon::Core::Exception::Builder 
(
    "DriverError" => 
    {
        "title" => "Driver error"
    },

);

1;

__END__

=head1 NAME

Eidolon::Driver::Exceptions - Eidolon driver exceptions.

=head1 SYNOPSIS

In error handler of your application (C<lib/Example/Error.pm>) you could write:

    if ($e eq "DriverError")
    {
        print "Driver error occured!";
    }
    else
    {
        $e->rethrow();
    }

=head1 DESCRIPTION

The I<Eidolon::Driver::Exceptions> package creates driver exceptions that are used
by all types of drivers.

=head1 EXCEPTIONS

=head2 DriverError

Base driver exception. All other driver exceptions subclass it.

=head1 SEE ALSO

L<Eidolon>, L<Eidolon::Core::Exception>,
L<Eidolon::Core::Exception::Builder>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut
