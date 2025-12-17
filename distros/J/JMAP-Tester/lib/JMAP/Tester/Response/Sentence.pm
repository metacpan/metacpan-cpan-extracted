use v5.20.0;
package JMAP::Tester::Response::Sentence 0.109;
# ABSTRACT: a single triple within a JMAP response

use Moo;

use experimental 'signatures';

use namespace::clean;

#pod =head1 OVERVIEW
#pod
#pod These objects represent sentences in the JMAP response.  That is, if your
#pod response is:
#pod
#pod   [
#pod     [ "messages", { ... }, "a" ],      # 1
#pod     [ "smellUpdates", { ... }, "b" ],  # 2
#pod     [ "smells",       { ... }, "b" ],  # 3
#pod   ]
#pod
#pod ...then #1, #2, and #3 are each a single sentence.
#pod
#pod The first item in the triple is accessed with the C<name> method.  The second
#pod is accessed with the C<arguments> method.  The third, with the C<client_id>
#pod method.
#pod
#pod =cut

has name      => (is => 'ro', required => 1);
has arguments => (is => 'ro', required => 1);
has client_id => (is => 'ro', required => 1);

has sentence_broker => (is => 'ro', required => 1);

sub _strip_json_types ($self, $whatever) {
  $self->sentence_broker->strip_json_types($whatever);
}

#pod =method as_triple
#pod
#pod =method as_stripped_triple
#pod
#pod C<as_triple> returns the underlying JSON data of the sentence, which may
#pod include objects used to convey type information for booleans, strings, and
#pod numbers.
#pod
#pod For unblessed data, use C<as_stripped_triple>.
#pod
#pod These return a three-element arrayref.
#pod
#pod =cut

sub as_triple ($self) { [ $self->name, $self->arguments, $self->client_id ] }

sub as_stripped_triple ($self) {
  $self->sentence_broker->strip_json_types($self->as_triple);
}

#pod =method as_pair
#pod
#pod =method as_stripped_pair
#pod
#pod C<as_pair> returns the same thing as C<as_triple>, but without the
#pod C<client_id>.  That means it returns a two-element arrayref.
#pod
#pod C<as_stripped_pair> returns the same minus JSON type information.
#pod
#pod =cut

sub as_pair ($self) { [ $self->name, $self->arguments ] }

sub as_stripped_pair ($self) {
  $self->sentence_broker->strip_json_types($self->as_pair);
}

#pod =method as_set
#pod
#pod This method returns a L<JMAP::Tester::Response::Sentence::Set> object for the
#pod current sentence.  That's a specialized Sentence for C<setFoos>-style JMAP
#pod method responses.
#pod
#pod =cut

sub as_set ($self) {
  unless ($self->name =~ m{/set$}) {
    return $self->sentence_broker->abort(
      sprintf(qq{tried to call ->as_set on sentence named "%s"}, $self->name)
    );
  }

  require JMAP::Tester::Response::Sentence::Set;
  return JMAP::Tester::Response::Sentence::Set->new({
    name         => $self->name,
    arguments    => $self->arguments,
    client_id    => $self->client_id,

    sentence_broker => $self->sentence_broker,
  });
}

#pod =method assert_named
#pod
#pod   $sentence->assert_named("theName")
#pod
#pod This method aborts unless the sentence's name is the given name.  Otherwise, it
#pod returns the sentence.
#pod
#pod =cut

sub assert_named ($self, $name) {
  Carp::confess("no name given") unless defined $name;

  return $self if $self->name eq $name;

  $self->sentence_broker->abort(
    sprintf qq{expected sentence named "%s" but got "%s"}, $name, $self->name
  );
}

sub TO_JSON ($self) {
  return [ $self->name, $self->arguments, $self->client_id ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Response::Sentence - a single triple within a JMAP response

=head1 VERSION

version 0.109

=head1 OVERVIEW

These objects represent sentences in the JMAP response.  That is, if your
response is:

  [
    [ "messages", { ... }, "a" ],      # 1
    [ "smellUpdates", { ... }, "b" ],  # 2
    [ "smells",       { ... }, "b" ],  # 3
  ]

...then #1, #2, and #3 are each a single sentence.

The first item in the triple is accessed with the C<name> method.  The second
is accessed with the C<arguments> method.  The third, with the C<client_id>
method.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 METHODS

=head2 as_triple

=head2 as_stripped_triple

C<as_triple> returns the underlying JSON data of the sentence, which may
include objects used to convey type information for booleans, strings, and
numbers.

For unblessed data, use C<as_stripped_triple>.

These return a three-element arrayref.

=head2 as_pair

=head2 as_stripped_pair

C<as_pair> returns the same thing as C<as_triple>, but without the
C<client_id>.  That means it returns a two-element arrayref.

C<as_stripped_pair> returns the same minus JSON type information.

=head2 as_set

This method returns a L<JMAP::Tester::Response::Sentence::Set> object for the
current sentence.  That's a specialized Sentence for C<setFoos>-style JMAP
method responses.

=head2 assert_named

  $sentence->assert_named("theName")

This method aborts unless the sentence's name is the given name.  Otherwise, it
returns the sentence.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Fastmail Pty. Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
