use v5.36;

package Ekorn::Pipeline::Factories;

use Exporter                qw(import);
use Ref::Util               qw(is_coderef);
use Ekorn::Pipeline         qw();
use Ekorn::Pipeline::Errors qw(croakf);
use Ekorn::Pipeline::Gather qw(gather);
use Ekorn::Pipeline::Sink   qw();
use Ekorn::Pipeline::Source qw();
use Ekorn::Pipeline::Stage  qw();

our @EXPORT_OK
    = qw(pipeline stage gather source generator yield sink_one sink_many);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# The values a generator's block has yielded in the run under way, if
# any: local to each run, so a generator read inside another's block
# keeps its own.
our $YIELDED;

# Return a pipeline of the stages given, each a code reference, a
# pipeline, or the name of one, looked up in the caller's package.
sub pipeline (@stages) {
    return Ekorn::Pipeline->pipeline_in(scalar caller, @stages);
}

# Return a Stage of the block given.
sub stage : prototype(&) ($code) {
    return Ekorn::Pipeline::Stage->new($code);
}


# Return a Source made for each run by the set-up given.
sub source : prototype(&) ($setup) {
    return Ekorn::Pipeline::Source->new($setup);
}


# Return a Source giving what the block yields: each run calls the block
# once, collecting every value it passes to yield, and gives them all
# as one step, so the block runs to its end before the first goes on.
sub generator : prototype(&) ($block) {
    croakf 'Expected a code reference' unless is_coderef($block);
    return Ekorn::Pipeline::Source->new(sub {
        my $ran;
        return sub () {
            return if $ran++;
            local $YIELDED = [];
            $block->();
            return @$YIELDED;
        };
    });
}


# Add the values given to what the generator whose block is running
# gives.
sub yield (@values) {
    croakf 'Expected yield to be called inside a generator' unless $YIELDED;
    push @$YIELDED, @values;
    return;
}


# Return a Sink made for each run by the set-up given, its result one
# value.
sub sink_one : prototype(&) ($setup) {
    return Ekorn::Pipeline::Sink->new_sink_one($setup);
}


# Return a Sink made for each run by the set-up given, its result a
# list.
sub sink_many : prototype(&) ($setup) {
    return Ekorn::Pipeline::Sink->new_sink_many($setup);
}

1;

__END__

=encoding utf8

=head1 NAME

Ekorn::Pipeline::Factories - words that make Ekorn's types

=head1 SYNOPSIS

    use Ekorn::Pipeline::Factories qw(:all);

    my $p = pipeline(
        stage { uc },
        'clean',
        take(5),
    );    # a pipeline, names looked up here

    my $lines = source {
        open my $fh, '<', $path or die "Can't read $path: $!\n";    # this run's
        return (
            sub ()     { my $line = readline $fh; defined $line ? $line : () },
            sub ($how) { close $fh },
        );
    };

    my $pairs = generator {
        for my $x (1 .. 3) { yield [$x, $_] for $x .. 3 }
    };

    my $total = sink_one {
        my $sum = 0;
        return (sub ($x) { $sum += $x }, sub () { $sum });
    };

    my $kept = sink_many {
        my @kept;
        return (sub ($x) { push @kept, $x }, sub () { @kept });
    };

=head1 DESCRIPTION

The words make Ekorn's types from what you write. Each is a short,
keyword-like function, one line over a class method: syntax, not
behaviour, so it lives here, not in the class it makes. Nothing is
exported by default; ask for each word, or for C<:all>.

=over

=item * C<pipeline(@stages)>, a pipeline, its stages able to name
pipelines;

=item * C<stage {...}>, a L<Ekorn::Pipeline::Stage>;

=item * C<gather {...}>, a L<Ekorn::Pipeline::Gather>;

=item * C<source {...}> and C<generator {...}>, a
L<Ekorn::Pipeline::Source>, with C<yield> for a generator;

=item * C<sink_one {...}> and C<sink_many {...}>, a
L<Ekorn::Pipeline::Sink> of one or of many.

=back

A package built on Ekorn uses them as they are, rather than making
words of its own for Ekorn's types.

=head1 FUNCTIONS

=head2 pipeline

    pipeline(@stages)

Returns a new pipeline of C<@stages>, each a code reference, a
pipeline, or the name of one, looked up now, in the package that
called C<pipeline>, unless it's qualified; or, given one name alone,
the pipeline it names, itself. It's C<<
Ekorn::Pipeline->pipeline_in(scalar caller, @stages) >>, as
L<Ekorn::Pipeline/pipeline_in> describes, with named pipelines.

=head2 stage

    stage { BLOCK }
    stage sub ($row) { ... }

Returns a stage of the block: called with each value, as any stage
is. It's an L<Ekorn::Pipeline::Stage>, an object called as a code
reference. To give it a signature, give it a sub. A Stage keeps what
it's given, so C<stage(\&trim)> never changes C<trim> itself.

=head2 gather

    gather { SET-UP }

Returns a stage made afresh for each run, whose set-up returns its
step, and, optionally, its flush and its end, as
L<Ekorn::Pipeline::Gather> describes. It's the same C<gather>
Ekorn::Pipeline::Gather exports.

=head2 source

    source { SET-UP }

Returns a source made afresh for each run. Its set-up returns its
step, called with nothing, again and again, giving the next value or
values, or an empty list when there are no more; optionally, its end,
told how the run ended; and, optionally, a context for the run, which
its stages ask for with L<Ekorn::Pipeline/run_context>. With a context
but no end, give C<undef> for the end, or return the parts by name, as
L<Ekorn::Pipeline/Made for a run> describes. It's an
L<Ekorn::Pipeline::Source>.

    sub up_to ($last) {
        return source {
            my $n = 0;    # this run's
            return sub () { $n < $last ? ++$n : () };
        };
    }

A source with nothing to set up or end needs no word: any code
reference is a source.

=head2 generator

    generator { BLOCK }

Returns a source giving what its block passes to L</yield>, as a
Python generator does. Perl can't pause a sub at C<yield>, so each run
calls the block once, to its end, and gives every value it yielded in
one step. So the block mustn't loop without end, and runs to its end
even when a stage after it takes only some. For a producer without
end, write a L</source> whose step gives a value each call.

Two of Perl's parsing rules apply: an empty block, C<generator {}>,
reads as an empty hash, so write C<generator { return }>; and
C<@{ generator {...} | ... }> reads as a hash slice, so keep the
generator in a variable first.

=head2 yield

    yield(@values)

Adds C<@values> to what the generator whose block is running gives. It
croaks outside one. A generator read inside another's block keeps its
own.

=head2 sink_one

    sink_one { SET-UP }

Returns a sink of one, made afresh for each run: its set-up returns
its step, called with each value, whose return is ignored; its flush,
called when its input runs out, giving its result, one value; and,
optionally, its end, told how the run ended. It's an
L<Ekorn::Pipeline::Sink>, made with C<new_sink_one>.

    my $longest = sink_one {
        my $max;
        return (
            sub ($s) { $max = $s if length $s > length($max // '') },
            sub ()   { $max },
        );
    };

    say Ekorn::Pipeline->new($longest)->(qw(a bbb cc));    # bbb

=head2 sink_many

    sink_many { SET-UP }

Returns a sink of many, as L</sink_one> does, whose flush gives a list.
Asked for one value, a pipeline ending in it gives the list as an array
reference, so write a sink of one value with C<sink_one>.

=head1 DIAGNOSTICS

=over

=item Expected yield to be called inside a generator

L</yield> was called with no generator's block running.

=item Expected a code reference

A word was given something other than a block or code reference.

=back

The words pass on the diagnostics of the classes they make, and
L</pipeline> those of L<Ekorn::Pipeline/pipeline_in>.

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Gather>,
L<Ekorn::Pipeline::Source>, L<Ekorn::Pipeline::Sink>,
L<Ekorn::Pipeline::Stage>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
