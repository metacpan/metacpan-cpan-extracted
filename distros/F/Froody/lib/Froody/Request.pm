=head1 NAME

Froody::Request - a Froody server request

=head1 DESCRIPTION

A request into a Froody server. Has a method attribute, and params for
the method. Normally you would use a subclass of this that gets the
method and params from some external source, for instance L<Froody::Request::CGI>.

=cut

package Froody::Request;
use warnings;
use strict;
use base qw( Froody::Base );

=head1 ATTRIBUTES

=over 4

=item method

The method of the request, probably taken from the URL of the CGI request
or something.

=item params

A hash of named parameters to pass to the request handler, taken from the
CGI params on the request or something.

=item type

The type of response wanted.  By default this returns xml.

=back

=cut

__PACKAGE__->mk_accessors(qw( method params));

sub type {
   my $self = shift;
   return $self->{type} || "xml"
     unless @_;
   $self->{type} = shift;
   return $self;
}

=head1 BUGS

None known.

Please report any bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Froody>

=head1 AUTHOR

Copyright Fotango 2005.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Froody>, L<Froody::Dispatch>

=cut
1;
