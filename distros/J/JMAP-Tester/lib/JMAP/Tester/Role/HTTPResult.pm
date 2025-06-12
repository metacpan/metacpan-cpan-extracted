use v5.14.0;
use warnings;
package JMAP::Tester::Role::HTTPResult 0.104;
# ABSTRACT: the kind of thing that you get back for an http request

use Moo::Role;

with 'JMAP::Tester::Role::Result';

#pod =head1 OVERVIEW
#pod
#pod This is the role consumed by the class of any object returned by
#pod L<JMAP::Tester>'s C<request> method.  In addition to
#pod L<JMAP::Tester::Role::Result>, this role provides C<http_response> to
#pod get at the underlying L<HTTP::Response> object. C<response_payload> will
#pod come from the C<as_string> method of that object.
#pod
#pod =cut

has http_response => (
  is => 'ro',
);

#pod =method response_payload
#pod
#pod Returns the raw payload of the response, if there is one. Empty string
#pod otherwise. Mostly this will be C<< $self->http_response->as_string >>
#pod but other result types may exist that don't have an http_response...
#pod
#pod =cut

sub response_payload {
  my ($self) = @_;

  return $self->http_response ? $self->http_response->as_string : '';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Role::HTTPResult - the kind of thing that you get back for an http request

=head1 VERSION

version 0.104

=head1 OVERVIEW

This is the role consumed by the class of any object returned by
L<JMAP::Tester>'s C<request> method.  In addition to
L<JMAP::Tester::Role::Result>, this role provides C<http_response> to
get at the underlying L<HTTP::Response> object. C<response_payload> will
come from the C<as_string> method of that object.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 METHODS

=head2 response_payload

Returns the raw payload of the response, if there is one. Empty string
otherwise. Mostly this will be C<< $self->http_response->as_string >>
but other result types may exist that don't have an http_response...

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Fastmail Pty. Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
