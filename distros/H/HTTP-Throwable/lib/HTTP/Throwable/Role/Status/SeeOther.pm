package HTTP::Throwable::Role::Status::SeeOther;
our $AUTHORITY = 'cpan:STEVAN';
$HTTP::Throwable::Role::Status::SeeOther::VERSION = '0.026';
use Moo::Role;

with(
    'HTTP::Throwable',
    'HTTP::Throwable::Role::Redirect',
    'HTTP::Throwable::Role::BoringText',
);

sub default_status_code { 303 }
sub default_reason      { 'See Other' }

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::SeeOther - 303 See Other

=head1 VERSION

version 0.026

=head1 DESCRIPTION

The response to the request can be found under a different URI
and SHOULD be retrieved using a GET method on that resource.
This method exists primarily to allow the output of a
POST-activated script to redirect the user agent to a selected
resource. The new URI is not a substitute reference for the
originally requested resource. The 303 response MUST NOT be
cached, but the response to the second (redirected) request
might be cacheable.

The different URI SHOULD be given by the Location field in
the response. Unless the request method was HEAD, the entity
of the response SHOULD contain a short hypertext note with a
hyperlink to the new URI(s).

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

# ABSTRACT: 303 See Other

#pod =head1 DESCRIPTION
#pod
#pod The response to the request can be found under a different URI
#pod and SHOULD be retrieved using a GET method on that resource.
#pod This method exists primarily to allow the output of a
#pod POST-activated script to redirect the user agent to a selected
#pod resource. The new URI is not a substitute reference for the
#pod originally requested resource. The 303 response MUST NOT be
#pod cached, but the response to the second (redirected) request
#pod might be cacheable.
#pod
#pod The different URI SHOULD be given by the Location field in
#pod the response. Unless the request method was HEAD, the entity
#pod of the response SHOULD contain a short hypertext note with a
#pod hyperlink to the new URI(s).
