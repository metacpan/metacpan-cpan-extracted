package HTTP::Throwable::Role::Status::BadRequest;
our $AUTHORITY = 'cpan:STEVAN';
$HTTP::Throwable::Role::Status::BadRequest::VERSION = '0.026';
use Moo::Role;

with(
    'HTTP::Throwable',
    'HTTP::Throwable::Role::BoringText',
);

sub default_status_code { 400 }

sub default_reason { 'Bad Request' }

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::BadRequest - 400 Bad Request

=head1 VERSION

version 0.026

=head1 DESCRIPTION

The request could not be understood by the server due to
malformed syntax. The client SHOULD NOT repeat the request
without modifications.

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

# ABSTRACT: 400 Bad Request

#pod =head1 DESCRIPTION
#pod
#pod The request could not be understood by the server due to
#pod malformed syntax. The client SHOULD NOT repeat the request
#pod without modifications.
