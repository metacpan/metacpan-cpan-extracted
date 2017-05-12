package Eidolon::Core::Exceptions;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Core/Exceptions.pm - core exception list
#
# ==============================================================================

use warnings;
use strict;

our $VERSION = "0.02"; # 2009-05-14 04:42:05

use Eidolon::Core::Exception::Builder
(
    "CoreError" => 
    {
        "title" => "Core error"
    },

    "CoreError::Compile" => 
    {
        "isa"   => "CoreError",
        "title" => "Compile error"
    },

    "CoreError::AbstractMethod" => 
    {
        "isa"   => "CoreError",
        "title" => "Abstract method called"
    },

    "CoreError::NoRouter" =>
    {
        "isa"   => "CoreError",
        "title" => "Router not found, cannot proceed the request"
    },

    "CoreError::NoErrorHandler" =>
    {
        "isa"   => "CoreError",
        "title" => "No error handler defined for the application"
    },

    "CoreError::Loader" => 
    {
        "isa"   => "CoreError",
        "title" => "Driver loader error"
    }, 

    "CoreError::Loader::InvalidDriver" => 
    {
        "isa"   => "CoreError::Loader",
        "title" => "Invalid driver type"
    },

    "CoreError::Loader::AlreadyLoaded" => 
    {
        "isa"   => "CoreError::Loader",
        "title" => "This type of driver is already loaded"
    },

    "CoreError::CGI" => 
    {
        "isa"   => "CoreError",
        "title" => "CGI error"
    },

    "CoreError::CGI::MaxPost" => 
    {
        "isa"   => "CoreError::CGI",
        "title" => "Too big POST request"
    },

    "CoreError::CGI::InvalidPOST" => 
    {
        "isa"   => "CoreError::CGI",
        "title" => "Invalid POST request"
    },

    "CoreError::CGI::FileSave" => 
    {
        "isa"   => "CoreError::CGI",
        "title" => "Error saving file"
    }
);

1;

__END__

=head1 NAME

Eidolon::Core::Exceptions - Eidolon core exception list.

=head1 SYNOPSIS

In error handler of your application (C<lib/Example/Error.pm>) you
could write:

    if ($e eq "CoreError::AbstractMethod")
    {
        print "Abstract method called";
    }
    elsif ($e eq "CoreError::CGI::InvalidPOST")
    {
        print "Malformed POST request";
    }

=head1 DESCRIPTION

The I<Eidolon::Core::Exceptions> package creates core exceptions that are used by
various core packages.

=head1 EXCEPTIONS

=head2 _Error

Base I<Eidolon> exception. All other exceptions subclass it.

=head2 CoreError

Base core exception. All other core exceptions subclass it.

=head2 CoreError::Compile

Compilation error. Thrown when driver or controller raised perl compile error
during require or use.

=head2 CoreError::AbstractMethod

Abstract method error. Thrown when abstract method is called.

=head2 CoreError::NoRouter

No router defined. Raised when application has no router driver defined in the
application configuration file.

=head2 CoreError::NoErrorHandler

No error handler defined. Raised when there is no error handler defined in the
application configuration.

=head2 CoreError::Loader

Driver loader exceptions. All other driver loader exceptions subclass it.

=head2 CoreError::Loader::InvalidDriver

Thrown when driver being loaded isn't subclassed from L<Eidolon::Driver> class.

=head2 CoreError::Loader::AlreadyLoaded

Thrown when driver of the given type is already loaded.

=head2 CoreError::CGI

CGI error. All other CGI errors subclass this exception.

=head2 CoreError::CGI::MaxPost

POST request size limit exceeded.

=head2 CoreError::CGI::InvalidPOST

Malformed POST request.

=head2 CoreError::CGI::FileSave

Error saving uploaded file (during I<multipart/form-data> form submission).

=head1 SEE ALSO

L<Eidolon>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut
