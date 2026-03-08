package Langertha::Raider::Result;
# ABSTRACT: Result object from a Raider raid
our $VERSION = '0.304';
use Moose;

use overload
  '""' => sub { $_[0]->text // '' },
  fallback => 1;


has type => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);


has text => (
  is  => 'ro',
  isa => 'Str',
  predicate => 'has_text',
);


has content => (
  is  => 'ro',
  isa => 'Str',
  predicate => 'has_content',
);


has options => (
  is  => 'ro',
  isa => 'ArrayRef',
  predicate => 'has_options',
);


sub is_final    { $_[0]->type eq 'final' }
sub is_question { $_[0]->type eq 'question' }
sub is_pause    { $_[0]->type eq 'pause' }
sub is_abort    { $_[0]->type eq 'abort' }


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Result - Result object from a Raider raid

=head1 VERSION

version 0.304

=head1 SYNOPSIS

    my $result = await $raider->raid_f('What files are here?');

    # Stringifies to text (backward compatible)
    say $result;

    # Check result type
    if ($result->is_final) {
        say "Final answer: $result";
    } elsif ($result->is_question) {
        say "Agent asks: " . $result->content;
        my $answer = <STDIN>;
        my $continued = await $raider->respond_f($answer);
    } elsif ($result->is_pause) {
        say "Agent paused: " . $result->content;
        my $continued = await $raider->respond_f('continue');
    } elsif ($result->is_abort) {
        say "Agent aborted: " . $result->content;
    }

=head1 DESCRIPTION

Wraps the outcome of a L<Langertha::Raider/raid_f> call. The C<type> field
indicates what happened:

=over 4

=item C<final> - The LLM produced a final text answer (in C<text>).

=item C<question> - The agent used C<raider_ask_user> and needs a response
(question in C<content>, optional choices in C<options>).

=item C<pause> - The agent used C<raider_pause> and is waiting to be resumed
(reason in C<content>).

=item C<abort> - The agent used C<raider_abort> and stopped (reason in C<content>).

=back

Uses C<overload> so stringification returns C<text>, preserving backward
compatibility with code that treats raid results as plain strings.

=head2 type

Result type: C<final>, C<question>, C<pause>, or C<abort>.

=head2 text

The final text answer from the LLM. Only set when C<type> is C<final>.

=head2 content

The question, pause reason, or abort reason. Set for non-final result types.

=head2 options

Optional list of choices for a C<question> result.

=head2 is_final

Returns true if this is a final text answer.

=head2 is_question

Returns true if the agent is asking the user a question.

=head2 is_pause

Returns true if the agent has paused.

=head2 is_abort

Returns true if the agent has aborted.

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
