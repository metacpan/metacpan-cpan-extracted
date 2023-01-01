package HTTP::Throwable::Role::Status::TemporaryRedirect 0.028;
our $AUTHORITY = 'cpan:STEVAN';

use Moo::Role;

with(
    'HTTP::Throwable',
    'HTTP::Throwable::Role::BoringText',
    'HTTP::Throwable::Role::Redirect',
);

sub default_status_code { 307 }
sub default_reason      { 'Temporary Redirect' }

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::TemporaryRedirect - 307 Temporary Redirect

=head1 VERSION

version 0.028

=head1 DESCRIPTION

The requested resource resides temporarily under a different URI.
Since the redirection MAY be altered on occasion, the client
SHOULD continue to use the Request-URI for future requests.
This response is only cacheable if indicated by a Cache-Control
or Expires header field.

The temporary URI SHOULD be given by the Location field in the
response. Unless the request method was HEAD, the entity of the
response SHOULD contain a short hypertext note with a hyperlink
to the new URI(s), since many pre-HTTP/1.1 user agents do not
understand the 307 status. Therefore, the note SHOULD contain
the information necessary for a user to repeat the original
request on the new URI.

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

# ABSTRACT: 307 Temporary Redirect

#pod =head1 DESCRIPTION
#pod
#pod The requested resource resides temporarily under a different URI.
#pod Since the redirection MAY be altered on occasion, the client
#pod SHOULD continue to use the Request-URI for future requests.
#pod This response is only cacheable if indicated by a Cache-Control
#pod or Expires header field.
#pod
#pod The temporary URI SHOULD be given by the Location field in the
#pod response. Unless the request method was HEAD, the entity of the
#pod response SHOULD contain a short hypertext note with a hyperlink
#pod to the new URI(s), since many pre-HTTP/1.1 user agents do not
#pod understand the 307 status. Therefore, the note SHOULD contain
#pod the information necessary for a user to repeat the original
#pod request on the new URI.
#pod
