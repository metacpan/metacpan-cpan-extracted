use v5.14.0;
package JMAP::Tester::Response::Paragraph 0.104;
# ABSTRACT: a group of sentences in a JMAP response

use Moo;

use JMAP::Tester::Abort 'abort';

use namespace::clean;

#pod =head1 OVERVIEW
#pod
#pod These objects represent paragraphs in the JMAP response.  That is, if your
#pod response is:
#pod
#pod   [
#pod     [ "messages", { ... }, "a" ],      # 1
#pod     [ "smellUpdates", { ... }, "b" ],  # 2
#pod     [ "smells",       { ... }, "b" ],  # 3
#pod   ]
#pod
#pod ...then #1 forms one paragraph and #2 and #3 together form another.  It goes by
#pod matching client ids.
#pod
#pod =cut

sub client_id {
  my ($self) = @_;
  $self->_sentences->[0]->client_id;
}

sub BUILD {
  abort("tried to build 0-sentence paragraph")
    unless @{ $_[0]->_sentences };

  my $client_id = $_[0]->_sentences->[0]->client_id;
  abort("tried to build paragraph with non-uniform client_ids")
    if grep {; $_->client_id ne $client_id } @{ $_[0]->_sentences };
}

has sentences => (is => 'bare', reader => '_sentences', required => 1);

#pod =method sentences
#pod
#pod The C<sentences> method returns a list of
#pod L<Sentence|JMAP::Tester::Response::Sentence> objects, one for each sentence
#pod in the paragraph.
#pod
#pod =cut

sub sentences { @{ $_[0]->_sentences } }

#pod =method sentence
#pod
#pod   my $sentence = $para->sentence($n);
#pod
#pod This method returns the I<n>th sentence of the paragraph.
#pod
#pod =cut

sub sentence {
  my ($self, $n) = @_;
  abort("there is no sentence for index $n")
    unless $self->_sentences->[$n];
}

#pod =method single
#pod
#pod   my $sentence = $para->single;
#pod   my $sentence = $para->single($name);
#pod
#pod This method throws an exception if there is more than one sentence in the
#pod paragraph.  If a C<$name> argument is given and the paragraph's single
#pod sentence doesn't have that name, an exception is raised.
#pod
#pod Otherwise, this method returns the sentence.
#pod
#pod =cut

sub single {
  my ($self, $name) = @_;

  my @sentences = $self->sentences;

  Carp::confess("more than one sentence in set, but ->single called")
    if @sentences > 1;

  Carp::confess("single sentence not of expected name <$name>")
    if defined $name && $name ne $sentences[0]->name;

  return $sentences[0];
}

#pod =method assert_n_sentences
#pod
#pod   my ($s1, $s2, ...) = $paragraph->assert_n_sentences($n);
#pod
#pod This method returns all the sentences in the paragarph, as long as there are
#pod exactly C<$n>.  Otherwise, it aborts.
#pod
#pod =cut

sub assert_n_sentences {
  my ($self, $n) = @_;

  Carp::confess("no sentence count given") unless defined $n;

  my @sentences = $self->sentences;

  unless (@sentences == $n) {
    abort("expected $n sentences but got " . @sentences)
  }

  return @sentences;
}

#pod =method sentence_named
#pod
#pod   my $sentence = $paragraph->sentence_named($name);
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
    abort(qq{no sentence found with name "$name"});
  }

  if (@sentences > 1) {
    abort(qq{found more than one sentence with name "$name"});
  }

  return $sentences[0];
}

#pod =method as_triples
#pod
#pod =method as_stripped_triples
#pod
#pod C<as_triples> returns an arrayref containing the result of calling
#pod C<as_triple> on each sentence in the paragraph. C<as_stripped_triples> removes
#pod JSON types.
#pod
#pod =cut

sub as_triples {
  [ map {; $_->as_triple } $_[0]->sentences ]
}

sub as_stripped_triples {
  [ map {; $_->as_stripped_triple } $_[0]->sentences ]
}

#pod =method as_pairs
#pod
#pod C<as_pairs> returns an arrayref containing the result of calling C<as_pair>
#pod on each sentence in the paragraph. C<as_stripped_pairs> removes JSON types.
#pod
#pod =cut

sub as_pairs {
  [ map {; $_->as_pair } $_[0]->sentences ]
}

sub as_stripped_pairs {
  [ map {; $_->as_stripped_pair } $_[0]->sentences ]
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Response::Paragraph - a group of sentences in a JMAP response

=head1 VERSION

version 0.104

=head1 OVERVIEW

These objects represent paragraphs in the JMAP response.  That is, if your
response is:

  [
    [ "messages", { ... }, "a" ],      # 1
    [ "smellUpdates", { ... }, "b" ],  # 2
    [ "smells",       { ... }, "b" ],  # 3
  ]

...then #1 forms one paragraph and #2 and #3 together form another.  It goes by
matching client ids.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 METHODS

=head2 sentences

The C<sentences> method returns a list of
L<Sentence|JMAP::Tester::Response::Sentence> objects, one for each sentence
in the paragraph.

=head2 sentence

  my $sentence = $para->sentence($n);

This method returns the I<n>th sentence of the paragraph.

=head2 single

  my $sentence = $para->single;
  my $sentence = $para->single($name);

This method throws an exception if there is more than one sentence in the
paragraph.  If a C<$name> argument is given and the paragraph's single
sentence doesn't have that name, an exception is raised.

Otherwise, this method returns the sentence.

=head2 assert_n_sentences

  my ($s1, $s2, ...) = $paragraph->assert_n_sentences($n);

This method returns all the sentences in the paragarph, as long as there are
exactly C<$n>.  Otherwise, it aborts.

=head2 sentence_named

  my $sentence = $paragraph->sentence_named($name);

This method returns the sentence with the given name.  If no such sentence
exists, or if two sentences with the name exist, the tester will abort.

=head2 as_triples

=head2 as_stripped_triples

C<as_triples> returns an arrayref containing the result of calling
C<as_triple> on each sentence in the paragraph. C<as_stripped_triples> removes
JSON types.

=head2 as_pairs

C<as_pairs> returns an arrayref containing the result of calling C<as_pair>
on each sentence in the paragraph. C<as_stripped_pairs> removes JSON types.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Fastmail Pty. Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
