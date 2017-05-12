package HTTP::Throwable::Role::Status::MovedPermanently;
our $AUTHORITY = 'cpan:STEVAN';
$HTTP::Throwable::Role::Status::MovedPermanently::VERSION = '0.026';
use Moo::Role;

with(
    'HTTP::Throwable',
    'HTTP::Throwable::Role::Redirect',
    'HTTP::Throwable::Role::BoringText',
);

sub default_status_code { 301 }
sub default_reason      { 'Moved Permanently' }

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::MovedPermanently - 301 Moved Permanently

=head1 VERSION

version 0.026

=head1 DESCRIPTION

The requested resource has been assigned a new permanent URI and
any future references to this resource SHOULD use one of the
returned URIs. Clients with link editing capabilities ought to
automatically re-link references to the Request-URI to one or more
of the new references returned by the server, where possible. This
response is cacheable unless indicated otherwise.

The new permanent URI SHOULD be given by the Location field in the
response. Unless the request method was HEAD, the entity of the
response SHOULD contain a short hypertext note with a hyperlink to
the new URI(s).

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: 301 Moved Permanently

#pod =head1 DESCRIPTION
#pod
#pod The requested resource has been assigned a new permanent URI and
#pod any future references to this resource SHOULD use one of the
#pod returned URIs. Clients with link editing capabilities ought to
#pod automatically re-link references to the Request-URI to one or more
#pod of the new references returned by the server, where possible. This
#pod response is cacheable unless indicated otherwise.
#pod
#pod The new permanent URI SHOULD be given by the Location field in the
#pod response. Unless the request method was HEAD, the entity of the
#pod response SHOULD contain a short hypertext note with a hyperlink to
#pod the new URI(s).
#pod
