package HTTP::Throwable::Role::Status::Found;
our $AUTHORITY = 'cpan:STEVAN';
$HTTP::Throwable::Role::Status::Found::VERSION = '0.026';
use Moo::Role;

with(
    'HTTP::Throwable',
    'HTTP::Throwable::Role::Redirect',
    'HTTP::Throwable::Role::BoringText',
);

sub default_status_code { 302 }
sub default_reason      { 'Found' }

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::Found - 302 Found

=head1 VERSION

version 0.026

=head1 DESCRIPTION

The requested resource resides temporarily under a different URI.
Since the redirection might be altered on occasion, the client
SHOULD continue to use the Request-URI for future requests. This
response is only cacheable if indicated by a Cache-Control or
Expires header field.

The temporary URI SHOULD be given by the Location field in the
response. Unless the request method was HEAD, the entity of the
response SHOULD contain a short hypertext note with a hyperlink
to the new URI(s).

=head1 ATTRIBUTES

=head2 location

This is a required string, which will be used in the Location header
when creating a PSGI response.

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

# ABSTRACT: 302 Found

#pod =head1 DESCRIPTION
#pod
#pod The requested resource resides temporarily under a different URI.
#pod Since the redirection might be altered on occasion, the client
#pod SHOULD continue to use the Request-URI for future requests. This
#pod response is only cacheable if indicated by a Cache-Control or
#pod Expires header field.
#pod
#pod The temporary URI SHOULD be given by the Location field in the
#pod response. Unless the request method was HEAD, the entity of the
#pod response SHOULD contain a short hypertext note with a hyperlink
#pod to the new URI(s).
#pod
#pod =attr location
#pod
#pod This is a required string, which will be used in the Location header
#pod when creating a PSGI response.
#pod
