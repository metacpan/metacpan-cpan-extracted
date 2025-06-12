use v5.14.0;
package JMAP::Tester::SentenceBroker 0.104;

use Moo;
with 'JMAP::Tester::Role::SentenceBroker';

use Data::OptList ();
use JMAP::Tester::Abort;
use JMAP::Tester::Response::Sentence;
use JMAP::Tester::Response::Paragraph;

has response => (
  is => 'ro',
  weak_ref => 1,
  required => 1,
);

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

sub abort {
  my ($self, $string, $diag_spec) = @_;

  $diag_spec //= [ 'Response sentences', sub { [ $_[0]->sentences ] } ];

  my @diagnostics;

  if ($diag_spec) {
    my $todo = Data::OptList::mkopt($diag_spec);

    PAIR: for my $pair (@$todo) {
      my ($label, $value) = @$pair;

      if (not defined $value) {
        push @diagnostics, "$label\n";
        next PAIR;
      }

      if (ref $value) {
        if (ref $value eq 'CODE') {
          $value = $value->($self->response);
        }

        $value = $self->response->dump_diagnostic($value);
      }

      push @diagnostics, "$label: $value";
      $diagnostics[-1] .= "\n" unless $value =~ /\n\z/;
    }
  }

  die JMAP::Tester::Abort->new({
    message => $string,
    (@diagnostics ? (diagnostics => \@diagnostics) : ()),
  });
}

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

version 0.104

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
