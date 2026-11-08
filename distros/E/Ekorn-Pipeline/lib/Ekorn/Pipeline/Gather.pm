use v5.36;

package Ekorn::Pipeline::Gather;

use Exporter  qw(import);
use Ref::Util qw(is_coderef);

use Ekorn::Pipeline::Errors qw(croakf);

use namespace::clean -except => 'import';

our @EXPORT = qw(gather);    ## no critic (Modules::ProhibitAutomaticExportation)

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# Return a stage a pipeline makes afresh for each run, by calling the
# block given, which returns the stage, and optionally a function called
# when the values run out.
sub gather : prototype(&) ($block) {
    croakf 'Expected a code reference' unless is_coderef($block);
    return bless sub { $block->() }, __PACKAGE__;
}

1;
__END__

=encoding utf8

=head1 NAME

Ekorn::Pipeline::Gather - a stage made afresh for each run, told when the values run out

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

A stage is a code reference, called with each value in turn. It can't
tell when the last value has gone by, and whatever it keeps in a
closure stays there from one run of its pipeline to the next. A stage
that gathers values, to give them in batches or all together, needs
both: state of its own on each run, and a call at the end.

C<gather> makes such a stage. Its block is called at the start of each
run of a pipeline, so whatever the block declares is fresh on each run:
each call of a pipeline with values, and each iterator made from it.
The block returns:

=over

=item * the stage, called with each value as any stage is;

=item * optionally, a function called with no arguments, and C<$_>
undefined, once the values have run out.

=back

What the end function returns goes through the rest of the stages, as
what a stage returns does: nothing, one value, or several. It's called
even when there were no values, so an end can give an empty result,
such as C<[]>. The ends are called in order, first stage first, and
what one returns goes through the stages after it before the next end
is called, so an end later in the pipeline gets everything sent to it.

A stage that keeps state of any kind, such as a count, should be made
with C<gather>, even without an end function, so that it starts afresh
on each run.

=head2 Stopping

After a L<Ekorn::Pipeline::Stop>, the ends of the stages after the one
that stopped are called, so they get the values before the stop, and
any it carries; those of the stage that stopped, and the stages before
it, are not, as nothing else is processed. An end can stop the pipeline
too: the values its stop carries go on, and the ends after it are
still called.

=head2 Context

Inside an end function, and the stages it sends values to,
L<Ekorn::Pipeline/ending> is true, so code that tells its stages about
the value they're given can say that the value comes from many, not
one.

=head1 FUNCTIONS

=head2 gather

    my $stage = gather { ...; return ($stage, $end) };

Returns a stage that a pipeline makes for each run by calling the
block. It's a code reference, blessed into Ekorn::Pipeline::Gather, so
it can be given wherever a stage can. C<gather> is exported by default;
to keep it out of your namespace:

    use Ekorn::Pipeline::Gather ();

=head1 DIAGNOSTICS

=over

=item Expected a code reference

C<gather> was given something other than a block or code reference.

=item Expected stage #%d, made with gather, to return one or two code references

A block given to C<gather> returned something other than a stage, or a
stage and an end function. Reported when a run starts: when the
pipeline is called with values, or an iterator is made from it.

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
