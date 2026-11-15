use v5.36;

package Ekorn::Pipeline::Gather;

use parent 'Ekorn::Pipeline::Element';

use Exporter  qw(import);
use Ref::Util qw(is_coderef);

use Ekorn::Pipeline::Errors qw(croakf);

use namespace::clean -except => 'import';

our @EXPORT = qw(gather);    ## no critic (Modules::ProhibitAutomaticExportation)

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# Return a stage a pipeline makes afresh for each run, by calling the
# block given, which returns the stage's step, and optionally its flush
# and its end.
sub gather : prototype(&) ($block) {
    return __PACKAGE__->new($block);
}


# Return a gather of the block given. Called, it calls the block, as
# the core does at the start of each run.
sub new ($class, $block) {
    croakf 'Expected a code reference' unless is_coderef($block);
    return bless {call => sub { $block->() }}, $class;
}


# Return what the block returns for a new run: the step, or a pipeline
# of steps, and optionally a flush and an end.
sub EKORN_STAGE ($self) {
    return $self->{call}->();
}

1;
__END__

=encoding utf8

=head1 NAME

Ekorn::Pipeline::Gather - a stage made afresh for each run, told when its values run out

=head1 SYNOPSIS

    use Ekorn::Pipeline::Gather;

    # Values in batches of $size, the last batch given at the end
    sub batches_of ($size) {
        return gather {
            my @batch;    # this run's
            return (
                sub ($x) { push @batch, $x; @batch == $size ? [splice @batch] : () },
                sub ()   { @batch ? [@batch] : () },
            );
        };
    }

    my $next = Ekorn::Pipeline->new(batches_of(500))->iterator($source);
    while (my($batch) = $next->()) { ... }

=head1 DESCRIPTION

A plain stage, a code reference, is called with each value in turn.
It can't tell when the last value has gone by. Whatever it keeps in a
closure stays there from one run of its pipeline to the next. A stage that
gathers values, to give them in batches or all together, needs both:
fresh state on each run, and a call at the end.

C<gather> makes such a stage. Its block is the stage's I<set-up>,
called at the start of each run, so whatever the block declares is
fresh each time. A run is a call of a pipeline with values, or an
iterator made from it. The block returns:

=over

=item * the I<step>: a code reference, called with each value as any
stage is, or a pipeline;

=item * optionally, the I<flush>, called with no arguments, and C<$_>
undefined, once its input has run out;

=item * optionally, the I<end>, called once, when the run has ended,
however it ended, told how, as L</Ends> describes.

=back

It returns them as a list, in that order, giving C<undef> for the flush
to have only an end, or by name, as a hash reference, as in
C<< {step => $step, end => $end} >>: L<Ekorn::Pipeline/Made for a run>
has how.

What the flush returns goes through the rest of the stages, just like
what a step returns: nothing, one value, or several. It's called even
when there were no values, so a flush can give an empty result, such as
C<[]>. Its input runs out when the values run out, or after a stop in a
stage before it.

The flushes are called in order, first stage first. What one flush
returns goes through the stages after it before the next flush is
called, so a flush later in the pipeline gets everything sent to it.

Make any stage that keeps state, such as a count, with C<gather>, even
without a flush, so that it starts afresh on each run.

The flush is what v0.2.0 called the I<end function>. Its place in what
the block returns hasn't changed, so a gather written for v0.2.0 works
as it did.

=head2 Ends

The end is for what must be done however the run ends, such as closing
a file or committing a transaction. It's called once the run has ended,
after every flush, and is given how the run ended, from where the stage
stands:

=over

=item * C<died>, if the run died, anywhere;

=item * C<stopped>, if its input was cut short, by a stop at or after
it, or by the run being ended from outside, as
L<Ekorn::Pipeline::Iterator/finish> does;

=item * C<done>, if its input ran out.

=back

What it returns is dropped. The ends are called in order, the source's
first, then each stage's, first stage first. An end that dies, in a run
that hadn't died, ends the run with its error, and every end after it is
told C<died>. In a run already dying, it's reported as a warning, naming
its stage, and the first error is kept. L<Ekorn::Pipeline/How a run
ends> has the rest.

=head2 A pipeline as the stage

A pipeline returned as the stage has its stages made for the run in
its place, as if they had been given to the pipeline there. A
C<gather> stage inside it is made afresh too, and a stop inside it
ends the whole run. So the block can build a pipeline for each run,
or choose one:

    # The first $n values of each run, numbered from 1
    sub first_numbered ($n) {
        return gather {
            my $i = 0;    # this run's
            Ekorn::Pipeline->new(
                sub { ++$i . ". $_" },
                take($n),
            );
        };
    }

The block's flush, if it returns one, is called after the flushes of
the pipeline's own stages, and its end after their ends. A stage
inside the pipeline is named in messages by its position in each, as
C<#2.3> for the third stage of the pipeline returned by stage #2.

=head2 Stopping

After a L<Ekorn::Pipeline::Stop>, the flushes of the stages after the
one that stopped are called. They get the values from before the stop,
and any it carries. The flushes of the stage that stopped, and of the
stages before it, aren't called, as nothing else is processed. Their
ends are, told C<stopped>, and the ends of the stages after it are told
C<done>.

A flush can stop the pipeline too. The values its stop carries go on,
and the flushes after it are still called.

=head2 Context

Inside a flush, and the stages it sends values to,
L<Ekorn::Pipeline/ending> is true. Code that tells its stages where a
value came from can use it to say the value comes from many, not
one.

=head1 FUNCTIONS

=head2 gather

    my $stage = gather { ...; return ($step, $flush, $end) };

Returns a stage that a pipeline makes afresh for each run, by calling
the block. It's an Ekorn::Pipeline::Gather, which can be called as a
code reference, so it can go wherever a stage can. C<gather> is
exported by default. To keep it out of your namespace:

    use Ekorn::Pipeline::Gather ();

=head1 METHODS

=head2 new

    my $stage = Ekorn::Pipeline::Gather->new($setup);

Returns a gather of C<$setup>, a code reference, as C<gather> does.
Anything else croaks. Called as a code reference, a gather calls its
set-up.

=head2 EKORN_STAGE

    my @parts = $stage->EKORN_STAGE;

Calls the set-up, for a new run, and returns what it returns: the
parts, as a list or by name. A run calls it as it starts; you needn't.

=head1 DIAGNOSTICS

=over

=item Expected a code reference

C<gather> was given something other than a block or code reference.

=item Expected stage #%s, made with gather, to return a code reference or a pipeline, and optionally a flush and an end

A block given to C<gather> returned something else. It's reported when
a run starts: when the pipeline is called with values, or an iterator
is made from it. The stage is named by its position, as
L<Ekorn::Pipeline/DIAGNOSTICS> describes.

=back

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Stop>, and the canned stages,
many made with it: L<Ekorn::Pipeline::Stages::Flow>,
L<Ekorn::Pipeline::Stages::Batch> and L<Ekorn::Pipeline::Stages::Taps>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
