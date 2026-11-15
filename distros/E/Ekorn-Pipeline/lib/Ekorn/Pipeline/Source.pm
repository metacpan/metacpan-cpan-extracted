use v5.36;

package Ekorn::Pipeline::Source;

use parent 'Ekorn::Pipeline::Element';

use Ref::Util               qw(is_coderef);
use Ekorn::Pipeline::Errors qw(croakf);
use namespace::clean;

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# Return a source made afresh for each run by the set-up given, which
# returns the source's step and, optionally, its end and a context for
# the run. Called directly, it croaks: a run of its own would never be
# ended, so what it opened would stay open.
sub new ($class, $setup) {
    croakf 'Expected a code reference' unless is_coderef($setup);
    return bless {
        setup => $setup,
        call  => sub { croakf 'Expected a source to be read through iterator' },
    }, $class;
}


# Return what the set-up returns for a new run: the step, and
# optionally the end and a context.
sub EKORN_SOURCE ($self) {
    return $self->{setup}->();
}

1;

__END__

=encoding utf8

=head1 NAME

Ekorn::Pipeline::Source - a source made afresh for each run

=head1 SYNOPSIS

    use Ekorn::Pipeline::Source;

    sub lines_of ($path) {
        return Ekorn::Pipeline::Source->new(sub {
            open my $fh, '<', $path or die "Can't read $path: $!\n";    # this run's
            return (
                sub ()     { my $line = readline $fh; defined $line ? $line : () },
                sub ($how) { close $fh },
            );
        });
    }

    my $next = Ekorn::Pipeline->new(take(2))->iterator(lines_of('names.txt'));
    # reads two lines, then closes the file

=head1 DESCRIPTION

A source gives the values a run starts with, one pull at a time. Any
code reference is one: called with nothing, it returns the next value
or values, and an empty list once there are no more. But a code
reference is the same closure in every run, and is never told when the
run has ended, so it can't close what it opened.

A source made with this class is made afresh for each run, by its
I<set-up>, a code reference called at the start of the run. The set-up
declares, with C<my>, whatever the run needs, such as a filehandle, and
returns closures sharing it:

=over

=item * the I<step>, called with nothing each time the run wants more
values, returning the next value or values, or an empty list at the
end. It's required;

=item * optionally, the I<end>, called once, when the run has ended,
however it ended, told how, as its argument: C<done> if the source was
read to its end, C<stopped> if the run was cut short before it was,
and C<died> if the run died. What it returns is dropped;

=item * optionally, a I<context>: anything the run's stages may ask
for with L<Ekorn::Pipeline/run_context>, such as a statement's
columns.

=back

It returns them as a list, in that order, giving C<undef> for the end
to give only a context, or by name, as a hash reference, as in C<<
{step => $step, context => $columns} >>: L<Ekorn::Pipeline/Made for a
run> has how.

So two iterators of the same pipeline, reading the same source, each
get their own filehandle, and each closes its own, when its run ends.
L<Ekorn::Pipeline/How a run ends> says when that is, and what each
part is told.

The step can stop the run with L<Ekorn::Pipeline::Stop>, when it has
had enough. The values the stop carries are its last, and it's told
C<done>.

A source goes where a source goes: given to
L<Ekorn::Pipeline/iterator>. It isn't a stage, and given to
L<Ekorn::Pipeline/new> as one, it croaks. Called directly, as a code
reference, it croaks too: a run of its own would never be ended, so
what it opened would stay open.

The word C<source {...}>, in L<Ekorn::Pipeline::Factories>, makes one
of these from a block.

A class of your own needn't be one of these to be a source. Any
object with an C<EKORN_SOURCE> method, returning the step and
optionally the end and the context, as a list or by name, is one.

=head1 METHODS

=head2 new

    my $source = Ekorn::Pipeline::Source->new($setup);

Returns a source made afresh for each run by C<$setup>, a code
reference, as L</DESCRIPTION> describes. Anything else croaks.

=head2 EKORN_SOURCE

    my @parts = $source->EKORN_SOURCE;

Calls the set-up, for a new run, and returns what it returns: the
parts, as a list or by name. A run calls it as it starts; you needn't.

=head1 DIAGNOSTICS

=over

=item Expected a code reference

L</new> was given something other than a code reference.

=item Expected a source to be read through iterator

A source was called as a code reference. Give it to
L<Ekorn::Pipeline/iterator> instead.

=item Expected the source to return a code reference, and optionally an end and a context

The set-up returned something else: no step, or a step or end that
isn't a code reference. It's reported as the run starts.

=back

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Sink>,
L<Ekorn::Pipeline::Iterator>, and the ready-made sources in
L<Ekorn::Pipeline::Sources>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
