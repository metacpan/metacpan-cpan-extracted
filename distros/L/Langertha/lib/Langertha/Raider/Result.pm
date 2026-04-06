package Langertha::Raider::Result;
# ABSTRACT: Result object from a Raider raid
our $VERSION = '0.309';
use Moose;
extends 'Langertha::Result';


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Result - Result object from a Raider raid

=head1 VERSION

version 0.309

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

Backward-compatible Raider-specific result class. It now subclasses
L<Langertha::Result> so Raider and Raid orchestration can share the same
result semantics.

=head2 type

Inherited from L<Langertha::Result>. One of C<final>, C<question>,
C<pause>, or C<abort>.

=head2 text

Inherited from L<Langertha::Result>. Final response text payload.

=head2 content

Inherited from L<Langertha::Result>. Question/pause/abort message.

=head2 options

Inherited from L<Langertha::Result>. Optional choices for question results.

=head2 is_final

Inherited predicate helper from L<Langertha::Result>.

=head2 is_question

Inherited predicate helper from L<Langertha::Result>.

=head2 is_pause

Inherited predicate helper from L<Langertha::Result>.

=head2 is_abort

Inherited predicate helper from L<Langertha::Result>.

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
