use v5.20.0;

package JMAP::Tester::Response 0.110;
# ABSTRACT: what you get in reply to a succesful JMAP request

use Moo;
use experimental 'signatures';

# We can't use 'sub sentencebroker;' as a stub here as it conflicts
# with older Role::Tiny versions (2.000006, 2.000008, and others).
# With the stub, we'd see this error during compilation:
#
# Can't use string ("-1") as a symbol ref while "strict refs" in use at
# /usr/share/perl5/Role/Tiny.pm line 382
#
# We could pin a newer Role::Tiny version but this fix is easy enough

has sentence_broker => (
  is    => 'ro',
  lazy  => 1,
  init_arg => undef,
  default  => sub {
    my ($self) = @_;
    JMAP::Tester::SentenceBroker->new({ response => $self });
  },
);

with 'JMAP::Tester::Role::SentenceCollection', 'JMAP::Tester::Role::HTTPResult';

use JMAP::Tester::Response::Sentence;
use JMAP::Tester::Response::Paragraph;
use JMAP::Tester::SentenceBroker;

use namespace::clean;

#pod =head1 OVERVIEW
#pod
#pod A JMAP::Tester::Response object represents the successful response to a JMAP
#pod request -- the kind where you've POSTed a JSON object with C<methodCalls>.  It
#pod is a successful L<JMAP::Tester::Role::Result>.
#pod
#pod A Response is used mostly to contain the responses to the individual methods
#pod passed in the request.  For all of that interface, consult
#pod L<JMAP::Tester::Role::SentenceCollection>.
#pod
#pod A Response is also a L<JMAP::Tester::Role::HTTPResult>, meaning it has a
#pod C<http_response> method that returns an L<HTTP::Response> object.
#pod
#pod =cut

sub is_success { 1 }

has items => (
  is       => 'bare',
  reader   => '_items',
  required => 1,
);

has wrapper_properties => (
  is       => 'ro',
);

sub items ($self) { @{ $self->_items } }

sub add_items ($self, @) {
  $self->abort("can't add items to " . __PACKAGE__);
}

sub default_diagnostics ($self) {
  return [ 'Response sentences', [ $self->sentences ] ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Response - what you get in reply to a succesful JMAP request

=head1 VERSION

version 0.110

=head1 OVERVIEW

A JMAP::Tester::Response object represents the successful response to a JMAP
request -- the kind where you've POSTed a JSON object with C<methodCalls>.  It
is a successful L<JMAP::Tester::Role::Result>.

A Response is used mostly to contain the responses to the individual methods
passed in the request.  For all of that interface, consult
L<JMAP::Tester::Role::SentenceCollection>.

A Response is also a L<JMAP::Tester::Role::HTTPResult>, meaning it has a
C<http_response> method that returns an L<HTTP::Response> object.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Fastmail Pty. Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
