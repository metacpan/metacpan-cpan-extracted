package HTTP::Throwable::Role::Status::ExpectationFailed;
our $AUTHORITY = 'cpan:STEVAN';
$HTTP::Throwable::Role::Status::ExpectationFailed::VERSION = '0.027';
use Moo::Role;

with(
    'HTTP::Throwable',
    'HTTP::Throwable::Role::BoringText',
);

sub default_status_code { 417 }
sub default_reason      { 'Expectation Failed' }

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::ExpectationFailed - 417 Expectation Failed

=head1 VERSION

version 0.027

=head1 DESCRIPTION

The expectation given in an Expect request-header field
could not be met by this server, or, if the server is a
proxy, the server has unambiguous evidence that the
request could not be met by the next-hop server.

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

# ABSTRACT: 417 Expectation Failed

#pod =head1 DESCRIPTION
#pod
#pod The expectation given in an Expect request-header field
#pod could not be met by this server, or, if the server is a
#pod proxy, the server has unambiguous evidence that the
#pod request could not be met by the next-hop server.
#pod
