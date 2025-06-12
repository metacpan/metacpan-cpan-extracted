use v5.14.0;
package JMAP::Tester::Role::SentenceCollection 0.104;

use Moo::Role;

requires 'sentence_broker';

BEGIN {
  for my $m (qw(
    client_ids_for_items
    sentence_for_item
    paragraph_for_items

    strip_json_types

    abort
  )) {
    my $sub = sub {
      my $self = shift;
      $self->sentence_broker->$m(@_);
    };
    no strict 'refs';
    *$m = $sub;
  }
}

requires 'items';
requires 'add_items';

after add_items => sub { $_[0]->_index_setup };

sub BUILD {
  $_[0]->_index_setup;
}

sub _index_setup {
  my ($self) = @_;

  my @cids = $self->client_ids_for_items([ $self->items ]);

  my $prev_cid;
  my $next_para_idx = 0;

  my %cid_indices;
  my @para_indices;

  for my $i (0 .. $#cids) {
    my $cid = $cids[$i];
    unless (defined $cid) {
      Carp::cluck("undefined client_id in position $i");
      next;
    }

    if (defined $prev_cid && $prev_cid ne $cid) {
      # We're transition from cid1 to cid2. -- rjbs, 2016-04-08
      $self->abort("client_id <$cid> appears in non-contiguous positions")
        if $cid_indices{$cid};

      $next_para_idx++;
    }

    push @{ $cid_indices{$cid} }, $i;
    push @{ $para_indices[ $next_para_idx ] }, $i;

    $prev_cid = $cid;
  }

  $self->_cid_indices(\%cid_indices);
  $self->_para_indices(\@para_indices);
}

# The reason we don't have cid-to-para and para-to-lines is that in the event
# that one cid appears in non-contiguous positions, we want to allow it, even
# though it's garbage.  -- rjbs, 2016-04-11
has cid_indices  => (is => 'bare', accessor => '_cid_indices');
has para_indices => (is => 'bare', accessor => '_para_indices');

#pod =method sentence
#pod
#pod   my $sentence = $response->sentence($n);
#pod
#pod This method returns the I<n>th L<Sentence|JMAP::Tester::Response::Sentence> of
#pod the response.
#pod
#pod =cut

sub sentence {
  my ($self, $n) = @_;

  my @items = $self->items;
  $self->abort("there is no sentence for index $n")
    unless my $item = $items[$n];

  return $self->sentence_for_item($item);
}

#pod =method sentences
#pod
#pod   my @sentences = $response->sentences;
#pod
#pod This method returns a list of all sentences in the response.
#pod
#pod =cut

sub sentences {
  my ($self) = @_;

  my @sentences = map {; $self->sentence_for_item($_) }
                  $self->items;

  return @sentences;
}

#pod =method single_sentence
#pod
#pod   my $sentence = $response->single_sentence;
#pod   my $sentence = $response->single_sentence($name);
#pod
#pod This method returns the only L<Sentence|JMAP::Tester::Response::Sentence> of
#pod the response, raising an exception if there's more than one Sentence.  If
#pod C<$name> is given, an exception is raised if the Sentence's name doesn't match
#pod the given name.
#pod
#pod =cut

sub single_sentence {
  my ($self, $name) = @_;

  my @items = $self->items;
  unless (@items == 1) {
    $self->abort(
      sprintf("single_sentence called but there are %i sentences", 0+@items)
    );
  }

  my $sentence = $self->sentence_for_item($items[0]);

  my $have = $sentence->name;
  if (defined $name && $have ne $name) {
    $self->abort(qq{single sentence has name "$have" not "$name"});
  }

  return $sentence;
}

#pod =method sentence_named
#pod
#pod   my $sentence = $response->sentence_named($name);
#pod
#pod This method returns the sentence with the given name.  If no such sentence
#pod exists, or if two sentences with the name exist, the tester will abort.
#pod
#pod =cut

sub sentence_named {
  my ($self, $name) = @_;

  Carp::confess("no name given") unless defined $name;

  my @sentences = grep {; $_->name eq $name } $self->sentences;

  unless (@sentences) {
    $self->abort(qq{no sentence found with name "$name"});
  }

  if (@sentences > 1) {
    $self->abort(qq{found more than one sentence with name "$name"});
  }

  return $sentences[0];
}

#pod =method assert_n_sentences
#pod
#pod   my ($s1, $s2, ...) = $response->assert_n_sentences($n);
#pod
#pod This method returns all the sentences in the response, as long as there are
#pod exactly C<$n>.  Otherwise, it aborts.
#pod
#pod =cut

sub assert_n_sentences {
  my ($self, $n) = @_;

  Carp::confess("no sentence count given") unless defined $n;

  my @sentences = $self->sentences;

  unless (@sentences == $n) {
    $self->abort("expected $n sentences but got " . @sentences)
  }

  return @sentences;
}

#pod =method paragraph
#pod
#pod   my $para = $response->paragraph($n);
#pod
#pod This method returns the I<n>th L<Paragraph|JMAP::Tester::Response::Paragraph>
#pod of the response.
#pod
#pod =cut

sub paragraph {
  my ($self, $n) = @_;

  $self->abort("there is no paragraph for index $n")
    unless my $indices = $self->_para_indices->[$n];

  my @items    = $self->items;
  my @selected = @items[ @$indices ];

  $self->paragraph_for_items(\@selected);
}

#pod =method paragraphs
#pod
#pod   my @paragraphs = $response->paragraphs;
#pod
#pod This method returns a list of all paragraphs in the response.
#pod
#pod =cut

sub paragraphs {
  my ($self) = @_;

  my @para_indices = @{ $self->_para_indices };
  my @items        = $self->items;

  my @paragraphs;
  for my $i_set (@para_indices) {
    push @paragraphs, $self->paragraph_for_items(
      [ @items[ @$i_set ] ]
    );
  }

  return @paragraphs;
}

#pod =method assert_n_paragraphs
#pod
#pod   my ($p1, $p2, ...) = $response->assert_n_paragraphs($n);
#pod
#pod This method returns all the paragraphs in the response, as long as there are
#pod exactly C<$n>.  Otherwise, it aborts.
#pod
#pod =cut

sub assert_n_paragraphs {
  my ($self, $n) = @_;

  Carp::confess("no paragraph count given") unless defined $n;

  my @para_indices = @{ $self->_para_indices };
  unless ($n == @para_indices) {
    $self->abort("expected $n paragraphs but got " . @para_indices)
  }

  return $self->paragraphs;
}

#pod =method paragraph_by_client_id
#pod
#pod   my $para = $response->paragraph_by_client_id($cid);
#pod
#pod This returns the paragraph for the given client id.  If there is no paragraph
#pod for that client id, an empty list is returned.
#pod
#pod =cut

sub paragraph_by_client_id {
  my ($self, $cid) = @_;

  Carp::confess("no client id given") unless defined $cid;

  $self->abort("there is no paragraph for client_id $cid")
    unless my $indices = $self->_cid_indices->{$cid};

  my @items    = $self->items;
  my @selected = @items[ @$indices ];

  return $self->paragraph_for_items(\@selected);
}

#pod =method as_triples
#pod
#pod =method as_stripped_triples
#pod
#pod This method returns an arrayref of arrayrefs, holding the data returned by the
#pod JMAP server.  With C<as_triples>, some of the JSON data may be in objects
#pod provided by L<JSON::Typist>. If you'd prefer raw data, use the
#pod C<as_stripped_triples> form.
#pod
#pod =cut

sub as_triples {
  my ($self) = @_;

  return [
    map {; $self->sentence_for_item($_)->as_triple }
    $self->items
  ];
}

sub as_stripped_triples {
  my ($self) = @_;

  return $self->strip_json_types($self->as_triples);
}

#pod =method as_pairs
#pod
#pod =method as_stripped_pairs
#pod
#pod These methods do the same thing as C<as_triples> and <as_stripped_triples>,
#pod but omit client ids.
#pod
#pod =cut

sub as_pairs {
  my ($self) = @_;

  return [
    map {; $self->sentence_for_item($_)->as_pair }
    $self->items
  ];
}

sub as_stripped_pairs {
  my ($self) = @_;

  return $self->strip_json_types($self->as_pairs);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Role::SentenceCollection

=head1 VERSION

version 0.104

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 METHODS

=head2 sentence

  my $sentence = $response->sentence($n);

This method returns the I<n>th L<Sentence|JMAP::Tester::Response::Sentence> of
the response.

=head2 sentences

  my @sentences = $response->sentences;

This method returns a list of all sentences in the response.

=head2 single_sentence

  my $sentence = $response->single_sentence;
  my $sentence = $response->single_sentence($name);

This method returns the only L<Sentence|JMAP::Tester::Response::Sentence> of
the response, raising an exception if there's more than one Sentence.  If
C<$name> is given, an exception is raised if the Sentence's name doesn't match
the given name.

=head2 sentence_named

  my $sentence = $response->sentence_named($name);

This method returns the sentence with the given name.  If no such sentence
exists, or if two sentences with the name exist, the tester will abort.

=head2 assert_n_sentences

  my ($s1, $s2, ...) = $response->assert_n_sentences($n);

This method returns all the sentences in the response, as long as there are
exactly C<$n>.  Otherwise, it aborts.

=head2 paragraph

  my $para = $response->paragraph($n);

This method returns the I<n>th L<Paragraph|JMAP::Tester::Response::Paragraph>
of the response.

=head2 paragraphs

  my @paragraphs = $response->paragraphs;

This method returns a list of all paragraphs in the response.

=head2 assert_n_paragraphs

  my ($p1, $p2, ...) = $response->assert_n_paragraphs($n);

This method returns all the paragraphs in the response, as long as there are
exactly C<$n>.  Otherwise, it aborts.

=head2 paragraph_by_client_id

  my $para = $response->paragraph_by_client_id($cid);

This returns the paragraph for the given client id.  If there is no paragraph
for that client id, an empty list is returned.

=head2 as_triples

=head2 as_stripped_triples

This method returns an arrayref of arrayrefs, holding the data returned by the
JMAP server.  With C<as_triples>, some of the JSON data may be in objects
provided by L<JSON::Typist>. If you'd prefer raw data, use the
C<as_stripped_triples> form.

=head2 as_pairs

=head2 as_stripped_pairs

These methods do the same thing as C<as_triples> and <as_stripped_triples>,
but omit client ids.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Fastmail Pty. Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
