package HTTP::Throwable::Role::Status::LengthRequired;
our $AUTHORITY = 'cpan:STEVAN';
$HTTP::Throwable::Role::Status::LengthRequired::VERSION = '0.026';
use Moo::Role;

with(
    'HTTP::Throwable',
    'HTTP::Throwable::Role::BoringText',
);

sub default_status_code { 411 }
sub default_reason      { 'Length Required' }

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::LengthRequired - 411 Length Required

=head1 VERSION

version 0.026

=head1 DESCRIPTION

The server refuses to accept the request without a defined
Content-Length. The client MAY repeat the request if it
adds a valid Content-Length header field containing the
length of the message-body in the request message.

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

# ABSTRACT: 411 Length Required

#pod =head1 DESCRIPTION
#pod
#pod The server refuses to accept the request without a defined
#pod Content-Length. The client MAY repeat the request if it
#pod adds a valid Content-Length header field containing the
#pod length of the message-body in the request message.
