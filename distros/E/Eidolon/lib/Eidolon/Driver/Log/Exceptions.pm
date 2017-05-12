package Eidolon::Driver::Log::Exceptions;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Driver/Log/Exceptions.pm - log driver exceptions
#
# ==============================================================================

use warnings;
use strict;

our $VERSION = "0.02"; # 2009-05-14 05:44:28

use Eidolon::Core::Exception::Builder 
(
    "DriverError::Log" => 
    {
        "isa"   => "DriverError",
        "title" => "Log driver error"
    },

    "DriverError::Log::Directory" => 
    {
        "isa"   => "DriverError::Log",
        "title" => "Cannot open log directory"
    },

    "DriverError::Log::Open" => 
    {
        "isa"   => "DriverError::Log",
        "title" => "Cannot open log file"
    }
);

1;

__END__

=head1 NAME

Eidolon::Driver::Log::Exceptions - Eidolon log driver exceptions.

=head1 SYNOPSIS

In error handler of your application (C<lib/Example/Error.pm>) you could write:

    if ($e eq "Error::Driver::Log::Open")
    {
        print "Cannot open log file!";
    }
    else
    {
        $e->rethrow();
    }

=head1 DESCRIPTION

The I<Eidolon::Driver::Log::Exceptions> package creates log driver exceptions that
are used by all log drivers.

=head1 EXCEPTIONS

=head2 Error::Driver::Log

Base log driver exception. All other log driver exceptions subclass it.

=head2 Error::Driver::Log::Directory

Error opening log directory. Thrown when log directory doesn't exist.

=head2 Error::Driver::Log::Open

Error opening log file. Thrown when driver cannot open log file for writing.

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
