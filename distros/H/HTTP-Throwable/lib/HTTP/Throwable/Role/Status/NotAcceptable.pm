package HTTP::Throwable::Role::Status::NotAcceptable;
our $AUTHORITY = 'cpan:STEVAN';
$HTTP::Throwable::Role::Status::NotAcceptable::VERSION = '0.027';
use Moo::Role;

with(
    'HTTP::Throwable',
    'HTTP::Throwable::Role::BoringText',
);

sub default_status_code { 406 }
sub default_reason      { 'Not Acceptable' }

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::NotAcceptable - 406 Not Acceptable

=head1 VERSION

version 0.027

=head1 DESCRIPTION

The resource identified by the request is only capable of generating
response entities which have content characteristics not acceptable
according to the accept headers sent in the request.

Unless it was a HEAD request, the response SHOULD include an entity
containing a list of available entity characteristics and location(s)
from which the user or user agent can choose the one most appropriate.
The entity format is specified by the media type given in the
Content-Type header field. Depending upon the format and the capabilities
of the user agent, selection of the most appropriate choice MAY be
performed automatically. However, this specification does not define
any standard for such automatic selection.

  Note: HTTP/1.1 servers are allowed to return responses which are
  not acceptable according to the accept headers sent in the
  request. In some cases, this may even be preferable to sending a
  406 response. User agents are encouraged to inspect the headers of
  an incoming response to determine if it is acceptable.

If the response could be unacceptable, a user agent SHOULD temporarily
stop receipt of more data and query the user for a decision on further
actions.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: 406 Not Acceptable

#pod =head1 DESCRIPTION
#pod
#pod The resource identified by the request is only capable of generating
#pod response entities which have content characteristics not acceptable
#pod according to the accept headers sent in the request.
#pod
#pod Unless it was a HEAD request, the response SHOULD include an entity
#pod containing a list of available entity characteristics and location(s)
#pod from which the user or user agent can choose the one most appropriate.
#pod The entity format is specified by the media type given in the
#pod Content-Type header field. Depending upon the format and the capabilities
#pod of the user agent, selection of the most appropriate choice MAY be
#pod performed automatically. However, this specification does not define
#pod any standard for such automatic selection.
#pod
#pod   Note: HTTP/1.1 servers are allowed to return responses which are
#pod   not acceptable according to the accept headers sent in the
#pod   request. In some cases, this may even be preferable to sending a
#pod   406 response. User agents are encouraged to inspect the headers of
#pod   an incoming response to determine if it is acceptable.
#pod
#pod If the response could be unacceptable, a user agent SHOULD temporarily
#pod stop receipt of more data and query the user for a decision on further
#pod actions.
