package HTTP::Throwable::Role::Status::TooManyRequests;
our $AUTHORITY = 'cpan:STEVAN';
$HTTP::Throwable::Role::Status::TooManyRequests::VERSION = '0.026';
use Moo::Role;

with(
    'HTTP::Throwable',
    'HTTP::Throwable::Role::BoringText',
);

sub default_status_code { 429 }
sub default_reason      { 'Too Many Requests' }

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::TooManyRequests - 429 Too Many Requests

=head1 VERSION

version 0.026

=head1 DESCRIPTION

The 429 status code indicates that the user has sent too many
requests in a given amount of time ("rate limiting"). The response
representations SHOULD include details explaining the condition,
and MAY include a Retry-After header indicating how to wait before
making a new request.

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

# ABSTRACT: 429 Too Many Requests

#pod =head1 DESCRIPTION
#pod
#pod The 429 status code indicates that the user has sent too many
#pod requests in a given amount of time ("rate limiting"). The response
#pod representations SHOULD include details explaining the condition,
#pod and MAY include a Retry-After header indicating how to wait before
#pod making a new request.
#pod
