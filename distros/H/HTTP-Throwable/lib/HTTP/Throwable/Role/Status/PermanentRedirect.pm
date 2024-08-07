package HTTP::Throwable::Role::Status::PermanentRedirect 0.028;
our $AUTHORITY = 'cpan:STEVAN';

use Moo::Role;

with(
    'HTTP::Throwable',
    'HTTP::Throwable::Role::BoringText',
    'HTTP::Throwable::Role::Redirect',
);

sub default_status_code { 308 }
sub default_reason      { 'Permanent Redirect' }

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::PermanentRedirect - 308 Permanent Redirect

=head1 VERSION

version 0.028

=head1 DESCRIPTION

This status code is defined in L<RFC 7238|http://tools.ietf.org/html/rfc7238>.

The 308 (Permanent Redirect) status code indicates that the target resource has
been assigned a new permanent URI and any future references to this resource
ought to use one of the enclosed URIs.

The server SHOULD generate a Location header field ([RFC7231], Section 7.1.2)
in the response containing a preferred URI reference for the new permanent URI.
The user agent MAY use the Location field value for automatic redirection.  The
server's response payload usually contains a short hypertext note with a
hyperlink to the new URI(s).

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Ricardo Signes <cpan@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: 308 Permanent Redirect

#pod =head1 DESCRIPTION
#pod
#pod This status code is defined in L<RFC 7238|http://tools.ietf.org/html/rfc7238>.
#pod
#pod The 308 (Permanent Redirect) status code indicates that the target resource has
#pod been assigned a new permanent URI and any future references to this resource
#pod ought to use one of the enclosed URIs.
#pod
#pod The server SHOULD generate a Location header field ([RFC7231], Section 7.1.2)
#pod in the response containing a preferred URI reference for the new permanent URI.
#pod The user agent MAY use the Location field value for automatic redirection.  The
#pod server's response payload usually contains a short hypertext note with a
#pod hyperlink to the new URI(s).
#pod
