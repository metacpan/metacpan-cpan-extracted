package Eidolon::Driver::Template::Exceptions;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Driver/Template/Exceptions.pm - template driver exceptions
#
# ==============================================================================

use warnings;
use strict;

our $VERSION = "0.02"; # 2009-05-14 05:44:54

use Eidolon::Core::Exception::Builder 
(
    "DriverError::Template" => 
    {
        "isa"   => "DriverError",
        "title" => "Template driver error"
    },

    "DriverError::Template::Directory" =>
    {
        "isa"   => "DriverError::Template",
        "title" => "Cannot open template directory"
    },

    "DriverError::Template::Open" =>
    {
        "isa"   => "DriverError::Template",
        "title" => "Cannot open template file"
    },

    "DriverError::Template::NotParsed" =>
    {
        "isa"   => "DriverError::Template",
        "title" => "Template must be parsed before rendering"
    }
);

1;

__END__

=head1 NAME

Eidolon::Driver::Template::Exceptions - Eidolon template driver exceptions.

=head1 SYNOPSIS

In error handler of your application (C<lib/Example/Error.pm>) you could write:

    if ($e eq "Error::Driver::Template::Open")
    {
        print "Cannot open template file!";
    }
    else
    {
        $e->rethrow();
    }

=head1 DESCRIPTION

The I<Eidolon::Driver::Template::Exceptions> package creates template driver 
exceptions that are used by all template drivers.

=head1 EXCEPTIONS

=head2 Error::Driver::Template

Base template driver exception. All other template driver exceptions subclass it.

=head2 Error::Driver::Template::Directory

Error opening template directory. Thrown when template directory doesn't exist.

=head2 Error::Driver::Template::Open

Error opening template file. Thrown when driver cannot open template file for 
reading.

=head2 Error::Driver::Template::NotParsed

Error rendering template file. Thrown when application attempts to render a
template that wasn't parsed.

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
