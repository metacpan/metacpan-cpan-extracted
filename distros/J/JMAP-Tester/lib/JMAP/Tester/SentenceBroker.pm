use v5.10.0;
package JMAP::Tester::SentenceBroker;
$JMAP::Tester::SentenceBroker::VERSION = '0.016';
use Moo;
with 'JMAP::Tester::Role::SentenceBroker';

use JMAP::Tester::Abort 'abort';
use JMAP::Tester::Response::Sentence;
use JMAP::Tester::Response::Paragraph;

sub client_ids_for_items {
  map {; $_->[2] } @{ $_[1] }
}

sub sentence_for_item {
  my ($self, $item) = @_;

  return JMAP::Tester::Response::Sentence->new({
    name      => $item->[0],
    arguments => $item->[1],
    client_id => $item->[2],

    sentence_broker => $self,
  });
}

sub paragraph_for_items {
  my ($self, $items) = @_;

  return JMAP::Tester::Response::Paragraph->new({
    sentences       => [ map {; $self->sentence_for_item($_) } @$items ],
  });
}

sub abort_callback { \&abort }

sub strip_json_types {
  state $typist = JSON::Typist->new;
  $typist->strip_types($_[1]);
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::SentenceBroker

=head1 VERSION

version 0.016

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by FastMail, Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
