use v5.10.0;

package JMAP::Tester::Response;
# ABSTRACT: what you get in reply to a succesful JMAP request
$JMAP::Tester::Response::VERSION = '0.015';
use Moo;
with 'JMAP::Tester::Role::Result';

use JMAP::Tester::Abort 'abort';
use JMAP::Tester::Response::Sentence;
use JMAP::Tester::Response::Paragraph;

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

has struct => (
  is       => 'bare',
  reader   => '_struct',
  required => 1,
);

has _json_typist => (
  is => 'ro',
  handles => {
    _strip_json_types => 'strip_types',
  },
);

sub BUILD {
  $_[0]->_index_setup;
}

# map names to index sets
# map CRS indices to index sets
sub _index_setup {
  my ($self) = @_;

  my $res = $self->_struct;

  my $prev_cid;
  my $next_para_idx = 0;

  my %cid_indices;
  my @para_indices;

  for my $i (0 .. $#$res) {
    my $cid = $res->[$i][2];

    unless (defined $cid) {
      Carp::cluck("no client_id for response sentence in position $i");
      next;
    }

    if (defined $prev_cid && $prev_cid ne $cid) {
      # We're transition from cid1 to cid2. -- rjbs, 2016-04-08
      abort("client_id <$cid> appears in non-contiguous positions")
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

  abort("there is no sentence for index $n")
    unless my $triple = $self->_struct->[$n];

  return JMAP::Tester::Response::Sentence->new({
    triple => $triple,
    _json_typist => $self->_json_typist,
  });
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

  my @sentences = map {;
    JMAP::Tester::Response::Sentence->new({
      triple       => $_,
      _json_typist => $self->_json_typist
    });
  } @{ $self->_struct };

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

  my @sentences = @{ $self->_struct };
  unless (@sentences == 1) {
    abort(
      sprintf("single_sentence called but there are %i sentences", 0+@sentences)
    );
  }

  if (defined $name && $sentences[0][0] ne $name) {
    abort(qq{single sentence has name "$sentences[0][0]" not "$name"});
  }

  return JMAP::Tester::Response::Sentence->new({
    triple       => $sentences[0],
    _json_typist => $self->_json_typist
  });
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

  my @sentences = grep {; $_->[0] eq $name } @{ $self->_struct };

  unless (@sentences) {
    abort(qq{no sentence found with name "$name"});
  }

  if (@sentences > 1) {
    abort(qq{found more than one sentence with name "$name"});
  }

  return JMAP::Tester::Response::Sentence->new({
    triple       => $sentences[0],
    _json_typist => $self->_json_typist
  });
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
    abort("expected $n sentences but got " . @sentences)
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

  abort("there is no paragraph for index $n")
    unless my $indices = $self->_para_indices->[$n];

  my @triples = @{ $self->_struct }[ @$indices ];
  return JMAP::Tester::Response::Paragraph->new({
    sentences => [ map {;
      JMAP::Tester::Response::Sentence->new({
        triple => $_,
        _json_typist => $self->_json_typist
      }) } @triples ],
    _json_typist => $self->_json_typist,
  });
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

  my @paragraphs;
  for my $i_set (@para_indices) {
    push @paragraphs, JMAP::Tester::Response::Paragraph->new({
      sentences => [
        map {;
          JMAP::Tester::Response::Sentence->new({
            triple => $_,
            _json_typist => $self->_json_typist
           }) } @{ $self->_struct }[ @$i_set ]
      ],
      _json_typist => $self->_json_typist,
    });
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
    abort("expected $n paragraphs but got " . @para_indices)
  }

  return unless $n;

  my $res = $self->_struct;

  my @sets;
  for my $i_set (@para_indices) {
    push @sets, JMAP::Tester::Response::Paragraph->new({
      sentences => [
        map {;
          JMAP::Tester::Response::Sentence->new({
            triple => $_,
            _json_typist => $self->_json_typist
           }) } @{$res}[ @$i_set ]
      ],
      _json_typist => $self->_json_typist,
    });
  }

  return @sets;
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

  abort("there is no paragraph for client_id $cid")
    unless my $indices = $self->_cid_indices->{$cid};

  my @triples = @{ $self->_struct }[ @$indices ];
  return JMAP::Tester::Response::Paragraph->new({
    sentences => [ map {;
      JMAP::Tester::Response::Sentence->new({
        triple => $_,
        _json_typist => $self->_json_typist
      }) } @triples ],
    _json_typist => $self->_json_typist,
  });
}

#pod =method as_struct
#pod
#pod =method as_stripped_struct
#pod
#pod This method returns an arrayref of arrayrefs, holding the data returned by the
#pod JMAP server.  With C<as_struct>, some of the JSON data may be in objects provided by
#pod L<JSON::Typist>. If you'd prefer raw data, use the C<as_stripped_struct> form.
#pod
#pod =cut

sub as_struct {
  my ($self) = @_;

  return [
    map {; JMAP::Tester::Response::Sentence->new({triple => $_})->as_struct }
    @{ $self->_struct }
  ];
}

sub as_stripped_struct {
  my ($self) = @_;

  return $self->_strip_json_types($self->as_struct);
}

#pod =method as_pairs
#pod
#pod =method as_stripped_pairs
#pod
#pod These methods do the same thing as C<as_struct> and <as_stripped_struct>,
#pod but omit client ids.
#pod
#pod =cut

sub as_pairs {
  my ($self) = @_;

  return [
    map {; JMAP::Tester::Response::Sentence->new({triple => $_})->as_pair }
    @{ $self->_struct }
  ];
}

sub as_stripped_pairs {
  my ($self) = @_;

  return $self->_strip_json_types($self->as_pairs);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Response - what you get in reply to a succesful JMAP request

=head1 VERSION

version 0.015

=head1 OVERVIEW

A JMAP::Tester::Response object represents the successful response to a JMAP
call.  It is a successful L<JMAP::Tester::Result>.

A Response is used mostly to contain the responses to the individual methods
passed in the request.

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

=head2 as_struct

=head2 as_stripped_struct

This method returns an arrayref of arrayrefs, holding the data returned by the
JMAP server.  With C<as_struct>, some of the JSON data may be in objects provided by
L<JSON::Typist>. If you'd prefer raw data, use the C<as_stripped_struct> form.

=head2 as_pairs

=head2 as_stripped_pairs

These methods do the same thing as C<as_struct> and <as_stripped_struct>,
but omit client ids.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by FastMail, Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
