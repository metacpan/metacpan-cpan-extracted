package Gantry::Exception;

use warnings;
use strict;

use Exception::Class (
    'Gantry::Exception' => {
        fields => [qw( message dump status status_line )],
    },
    'Gantry::Exception::Redirect' => {
        isa => 'Gantry::Exception',
    },
    'Gantry::Exception::RedirectPermanently' => {
        isa => 'Gantry::Exception',
    },
    'Gantry::Exception::Declined' => {
        isa => 'Gantry::Exception',
    }
);

1;

__END__

=head1 NAME

Gantry::Exceptions - Structured exceptions for Gantry

=head1 SYNOPSIS

This module defines structured exceptions for Gantry.

=head1 DESCRIPTION

This module extends Exception::Class and defines a base set of exceptions for
Gantry. You can extend this class with your own exceptions. When you do this,
you will need to write an exception handler named exception_handler(). This 
method will recieve one parameter, which is the thrown exception. If an 
handler is not defined. A HTTP 500 error will be generated.

=over 4

=item Gantry::Exception

This can be used to generate exceptions within your application. An exception
can take the following parametrs:

 status      - a numeric status code
 status_line - a text line to be placed in a log file
 message     - text to be sent to the browser
 dump        - a dump of whatever

You will also need to write a custom exception handler. For example,
say you want to generate a 402 exception. You would do the following:

=over 4

 ...

 Gantry::Exception->throw(
     status => 402,
     status_line => 'payment required',
     message => 'gimme all your money, and your luvin too...'
 );

 ...

 sub exception_handler {
     my ($self, $X) = @_;

     my $status = $X->status;

     if ($status == 402) {

         # do something useful

    }

    return $status;

 }

=back

=item Fields()

  Inherited accessor method from Exception::Class.
  
=item dump()

  Accessor method for dump attribute.

=item message()

  Accessor method for message attribute.
  
=item status()

  Accessor method for status attribute.
  
= item status_line()

  Accessor method for status_line attribute.

=item Gantry::Exception::Redirect

You can use this to force a HTTP "Found" (302) to the browser. As an alternative 
you can use the relocate() method for existing code.

=over 4

Example:

 Gantry::Exception::Redirect->throw('/login');

 $self->relocate('/login');

=back

=item Gantry::Exception::RedirectPermanently

You can use this to force a HTTP "Moved Permanently" (301) to the browser. As 
an alternative you can use the relocate_permanently() method for existing code.

=over 4

Example:

 Gantry::Exception::RedirectPermanently->throw('/somewhere');

 $self->relocate_permanently('/somewhere');

=back

=item Gantry::Exception::Declined

Primiarily used internally by Gantry. It will produce a status page when a url
is not defined within your controllers.

=back

=head1 SEE ALSO

 Gantry
 Gantry::State::Exceptions
 Exception::Class

=head1 AUTHOR

Kevin L. Esteb <kesteb@wsipc.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
