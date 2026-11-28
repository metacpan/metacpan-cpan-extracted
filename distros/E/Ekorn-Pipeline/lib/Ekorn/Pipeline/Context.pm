use v5.36;

package Ekorn::Pipeline::Context;

use Exporter qw(import);

# The functions are defined by Ekorn::Pipeline, as they read what it
# keeps of the run running.
use Ekorn::Pipeline qw();

our $VERSION = 'v0.5.0';

our @EXPORT_OK   = qw(result_number result_original kept_origin);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

1;
__END__

=encoding utf8

=head1 NAME

Ekorn::Pipeline::Context - what a stage can ask about the result it's making

=head1 SYNOPSIS

    use Ekorn::Pipeline;
    use Ekorn::Pipeline::Context qw(result_number result_original);

    my @lines = Ekorn::Pipeline->new(
        sub { $_->{plays} > 6000 ? $_ : () },
        sub { result_number . ". $_->{title}" },
    )->(@tracks);    # 1. Dancing Queen, 2. Parklife, ...

    Ekorn::Pipeline->new(
        sub { $_ * 2 },
        sub { say result_original, ' became ', $_; $_ },
    )->(1 .. 3);     # 1 became 2, 2 became 4, 3 became 6

=head1 DESCRIPTION

Each run of a pipeline counts the results it makes, and keeps the value
each is being made from, so that a stage can ask which result it's
making, and from what. A I<result> is a value that leaves the last
stage, or that reaches a sink. Each run counts its own: a pipeline run
inside a stage, a tee's branch, and an iterator read as a source each
count theirs from 1, and leave the count of the run around them as it
was.

They're for a run's stages: its steps, flushes and sinks. Outside a
run, and in an end, they give undef. In a source's step, they give
where the run reading it has got to, which isn't promised: ask them in
a stage.

Every run counts, whether its stages ask or not. Measured on Perl 5.36
and 5.44, it costs a value about 15 to 75 nanoseconds, more on an
iterator's C<next>, which counts once a call, than on a pushed run or
C<all>, which count once a run: 1 to 12% through one stage that does
nothing, and less through stages that do work. Roadmap 2026-0046's
record has the measurements.

The run's context, which its source gives, is asked with
L<Ekorn::Pipeline/run_context>, and whether the stages are handling a
flush's values with L<Ekorn::Pipeline/ending>.

A stage that holds values back says where each value it gives came
from, with L</kept_origin>, so the stages after it get the right
original.

It's new in v0.3.11. Nothing is exported by default; C<:all> gives
all three, and so does L<Ekorn::Pipeline::Tooling>, in C<:context> and
C<:all>, from v0.3.15; C<kept_origin> is new in v0.5.0.
DBIx::Squirrel::Tooling exports the same functions under the same
names, from its v3.6.1, so importing both Toolings gives one of each.

=head1 FUNCTIONS

Each takes no arguments, and has an empty prototype, so a bare call is
a term, as a constant is: C<result_number + 1> adds one, and
C<result_original // 'none'> gives C<'none'> where there's none. In
v0.3.11, they had no prototype, so C<result_number + 1> died with "Too
many arguments", and C<//> after either began a pattern.

=head2 kept_origin

    my $origin = kept_origin;
    my @marked = $origin->gives(@values);

For a stage that holds values back, to give them later, as
C<take_last> does: it gives values the run has gone past, so the
stages after it would see the original of the value the run got to
last, not of the one theirs was made from. Such a stage says so, with
C<< holds => 1 >> among its parts, by name (L<Ekorn::Pipeline/Made for
a run>); in its step, as it keeps a value, calls C<kept_origin>; and
gives what it made from that value marked, by the origin's C<gives>:

    sub one_behind () {
        return gather {
            my @held;    # [value, origin]
            my $give = sub ($held) { $held->[1]->gives($held->[0]) };
            return {
                step => sub ($value) {
                    push @held, [$value, kept_origin];
                    return @held > 1 ? $give->(shift @held) : ();
                },
                flush => sub () { map { $give->($_) } splice @held },
                holds => 1,
            };
        };
    }

C<kept_origin> returns the value's I<origin>: an opaque object, an
C<Ekorn::Pipeline::Origin>, holding what L</result_original> answers
for the value then, as later its source may answer for another. Its
method C<gives> returns each of the values given marked as made from
that value, and the run takes the mark off each before the stages
after the stage get it, with that value's original, in a flush too. A
value the stage gives unmarked was made from many values, so has none,
as a batch has.
Only what the stage gives is unmarked, not a marked value inside a
structure it gives.

=over

=item * The origin is captured as the value is kept, in the step it came
to: a source's original part, which answers for the value it gave
last, is asked then, and only by a stage that holds values back.

=item * It works only in a run with a stage that holds values back, and
croaks elsewhere, a run nested in such a stage's step included. It
doesn't tell one stage of the run from another, so a stage that
doesn't hold values back mustn't call it; in a flush, which has no
value, it gives an origin of nothing.

=item * A stage that holds values back but doesn't say so is taken for
one that maps, as every stage was before v0.5.0.

=back

New in v0.5.0.

=head2 result_number

    my $n = result_number;

The number of the result being made, counting from 1: the run's
results so far, plus one. While a stage drops values, it stays the
same, as no result has been made. Each value a stage returns in place
of one is a result of its own, so they're numbered one after another.
In a flush, it's the number of the first value the flush returns.

=head2 result_original

    my $original = result_original;

The value the result is being made from, as the run's source gave it,
or as it was pushed, before any stage changed it. Each value a stage
returns in place of one, and each a stop carries, has the original of
the value it was made from. In a flush, and the stages after it, the
values a flush gives have none, so it's undef, unless a stage that
holds values back says where they came from (L</kept_origin>). For a
run reading an iterator, it's the value the iterator handed out, not
that iterator's own original, unless the source says otherwise, as
follows.

A source can say better, by giving an I<original> part, as
L<Ekorn::Pipeline::Source> describes: a statement's source, for
instance, giving the row it fetched last, when what it hands out is
made from the row. Then C<result_original> gives what that says,
calling it only when asked, and a run reading an iterator of that
source's run gets it too, so the row reaches every pipeline in a
chain. A flush's values have none, whatever it says, unless a stage
that holds values back says where they came from. New in v0.3.13.

The value itself, not a copy: a stage that changes a hash changes the
original too.

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Tooling>,
L<Ekorn::Pipeline::Manual::Reference>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
