package Langertha::Result;
# ABSTRACT: Common result object for Raider and Raid execution
our $VERSION = '0.307';
use Moose;

use overload
  '""' => sub { $_[0]->text // '' },
  fallback => 1;


has type => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);


has text => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_text',
);


has content => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_content',
);


has options => (
  is        => 'ro',
  isa       => 'ArrayRef',
  predicate => 'has_options',
);


has data => (
  is        => 'ro',
  predicate => 'has_data',
);


has context => (
  is        => 'ro',
  predicate => 'has_context',
);


sub is_final    { $_[0]->type eq 'final' }
sub is_question { $_[0]->type eq 'question' }
sub is_pause    { $_[0]->type eq 'pause' }
sub is_abort    { $_[0]->type eq 'abort' }


sub as_hash {
  my ( $self ) = @_;
  return {
    type    => $self->type,
    ($self->has_text    ? ( text    => $self->text )    : ()),
    ($self->has_content ? ( content => $self->content ) : ()),
    ($self->has_options ? ( options => $self->options ) : ()),
    ($self->has_data    ? ( data    => $self->data )    : ()),
  };
}


sub with_context {
  my ( $self, $context ) = @_;
  return ref($self)->new(
    %{$self->as_hash},
    context => $context,
  );
}


sub final {
  my ( $class, $text, %args ) = @_;
  return $class->new(
    type => 'final',
    (defined $text ? ( text => "$text" ) : ()),
    %args,
  );
}

sub question {
  my ( $class, $content, %args ) = @_;
  return $class->new(
    type    => 'question',
    content => "$content",
    %args,
  );
}

sub pause {
  my ( $class, $content, %args ) = @_;
  return $class->new(
    type    => 'pause',
    content => "$content",
    %args,
  );
}

sub abort {
  my ( $class, $content, %args ) = @_;
  return $class->new(
    type    => 'abort',
    content => "$content",
    %args,
  );
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Result - Common result object for Raider and Raid execution

=head1 VERSION

version 0.307

=head1 SYNOPSIS

    my $r = Langertha::Result->final('done');

    if ($r->is_question) {
      ...
    }

    say "$r"; # stringifies to text (or empty string)

=head1 DESCRIPTION

Unified result type used by runnable nodes in Langertha orchestration.
Represents one of four high-level outcomes:

=over 4

=item * C<final> - successful completion

=item * C<question> - needs user input

=item * C<pause> - intentionally paused / resumable

=item * C<abort> - explicit stop / error

=back

L<Langertha::Raider::Result> subclasses this class for backward-compatible
Raider behavior.

=head2 type

Result type: C<final>, C<question>, C<pause>, or C<abort>.

=head2 text

Final output text, usually used with C<type =E<gt> final>.

=head2 content

Auxiliary text payload for non-final outcomes (question/pause/abort).

=head2 options

Optional choices for question-style results.

=head2 data

Optional structured payload for callers/orchestrators.

=head2 context

Optional run context attached to the result.

=head2 is_final

Returns true for C<type =E<gt> final>.

=head2 is_question

Returns true for C<type =E<gt> question>.

=head2 is_pause

Returns true for C<type =E<gt> pause>.

=head2 is_abort

Returns true for C<type =E<gt> abort>.

=head2 as_hash

Returns a plain hashref representation (without C<context>).

=head2 with_context

    my $with_ctx = $result->with_context($ctx);

Returns a cloned result object with C<context> attached.

=head2 final

    my $r = Langertha::Result->final('ok');

Constructor helper for final results.

=head2 question

    my $r = Langertha::Result->question('Which option?', options => ['a','b']);

Constructor helper for question results.

=head2 pause

    my $r = Langertha::Result->pause('Waiting for external event');

Constructor helper for pause results.

=head2 abort

    my $r = Langertha::Result->abort('Cannot continue');

Constructor helper for abort results.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
