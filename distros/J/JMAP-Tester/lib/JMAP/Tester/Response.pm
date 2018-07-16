use v5.10.0;

package JMAP::Tester::Response;
# ABSTRACT: what you get in reply to a succesful JMAP request
$JMAP::Tester::Response::VERSION = '0.019';
use Moo;
with 'JMAP::Tester::Role::SentenceCollection', 'JMAP::Tester::Role::Result';

use JMAP::Tester::Response::Sentence;
use JMAP::Tester::Response::Paragraph;
use JMAP::Tester::SentenceBroker;

use namespace::clean;

#pod =head1 OVERVIEW
#pod
#pod A JMAP::Tester::Response object represents the successful response to a JMAP
#pod call.  It is a successful L<JMAP::Tester::Result>.
#pod
#pod A Response is used mostly to contain the responses to the individual methods
#pod passed in the request.
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

sub items { @{ $_[0]->_items } }

sub add_items {
  $_[0]->sentence_broker->abort_callback->("can't add items to " . __PACKAGE__);
}

sub sentence_broker {
  state $BROKER = JMAP::Tester::SentenceBroker->new;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Response - what you get in reply to a succesful JMAP request

=head1 VERSION

version 0.019

=head1 OVERVIEW

A JMAP::Tester::Response object represents the successful response to a JMAP
call.  It is a successful L<JMAP::Tester::Result>.

A Response is used mostly to contain the responses to the individual methods
passed in the request.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by FastMail, Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
