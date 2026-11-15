use v5.36;

package Ekorn::Pipeline::Iterator;

use parent 'Ekorn::Pipeline::Element';

use Carp                    qw();
use Ekorn::Pipeline::Errors qw(croakf);
use namespace::clean;

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# Return an iterator, calling $next for each value, whose run $end_run
# ends from outside, $context is the context its run's source gave,
# $ended says how its run ended, $spent whether it has handed out
# everything it will, and $all, if given, gives every value still to
# come in one call, as calling $next until it gives none would.
sub new (
    $class, $next, $end_run, $context = undef, $ended = sub () { return },
    $spent = sub () { return }, $all = undef,
) {
    return bless {
        call    => $next,
        end_run => $end_run,
        context => $context,
        ended   => $ended,
        spent   => $spent,
        all     => $all,
    }, $class;
}


# Return how the run ended: "done" if its source was read to its end,
# "stopped" if the reading was cut short, by a stop or from outside, or
# values still to be handed out were dropped, and "died" if anything in
# it died; nothing until the iterator has given all it will.
sub ended ($self) {
    return $self->{ended}->();
}


# End the run, if it hasn't ended, as from outside: each part is told
# how from where it stands, and nothing more is handed out.
sub finish ($self) {
    $self->{end_run}->();
    return;
}


# Return the values still to be handed out, reading the run to its end:
# as a list, or, asked for one value, an array reference of them. A
# method, only ever called as $iterator->all, so it can't be mistaken
# for Perl's all, a keyword from 5.42.
sub all ($self) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my @all;
    if (my $all = $self->{all}) {
        @all = $all->();
    }
    else {
        my $next = $self->{call};
        while (my($value) = $next->()) { push @all, $value }
    }
    return wantarray ? @all : \@all;
}


# Return the next value, or undef if there's none, and end the run, so
# nothing more is read.
sub first ($self) {
    my($value) = $self->{call}->();
    $self->finish;
    return $value;
}


# Return the next value, or undef if there's none, asserting it's the
# only one: if there's another, warn. The run ends either way.
sub single ($self) {
    my $next = $self->{call};
    my($value) = $next->();
    Carp::carp 'Expected only one item, but there were more'
        if my($more) = $next->();
    $self->finish;
    return $value;
}


# An iterator is a source: of the values its run gives, the run ended
# from outside when the run reading it ends, passing on its context.
sub EKORN_SOURCE ($self) {
    croakf
        'Expected a source with values still to give: an iterator is one run, and this one is spent'
        if $self->{spent}->();
    my $next = $self->{call};
    return {
        step    => sub () { $next->() },
        end     => sub ($how) { $self->finish },
        context => $self->{context},
    };
}


# An iterator let go ends its run.
sub DESTROY ($self) {
    local $@ = undef;
    $self->{end_run}->();
    return;
}

1;

__END__

=encoding utf8

=head1 NAME

Ekorn::Pipeline::Iterator - one run, handing out its values as they're pulled

=head1 SYNOPSIS

    my $next = Ekorn::Pipeline->new(@stages)->iterator($source);

    while (my($value) = $next->()) { ... }    # one value per call

    my @rest  = $next->all;       # every value still to come
    my $first = $next->first;     # the next value; then the run ends
    my $one   = $next->single;    # the same, warning if there's another

    $next->finish;                # end the run now
    say $next->ended;             # done, stopped or died

=head1 DESCRIPTION

An iterator is one run of a pipeline, made by
L<Ekorn::Pipeline/iterator>. Called as a code reference, with nothing,
it hands out the next value to come out of the stages, pulling its
source only as it needs more. It returns an empty list once the values
run out, and on every call after. Read it in list context, so that an
C<undef> value isn't taken for the end.

The run ends as soon as nothing in it can still act on a value: once
its source has run out or been stopped, and every value has gone
through the stages. Then each part's end is called, told how the run
ended from where it stands, as L<Ekorn::Pipeline/How a run ends>
describes. A run that dies ends there too, and every call after
returns an empty list.

=head2 An iterator left unfinished

An iterator let go before its values run out ends its run when the
last reference to it goes, as L</finish> does. So a source that opened
a file closes it there and then:

    my($first) = Ekorn::Pipeline->new(sub { uc })->iterator($lines)->();

Perl destroys a lexical iterator as soon as it goes out of scope. One
kept until the program ends is destroyed during global destruction,
when the order in which objects are destroyed isn't guaranteed, so an
end mustn't rely on other objects then.

=head2 Pulling many values

An iterator is an object, so each call goes through Perl's overloading
of C<&{}> to find its code. A loop pulling many values can take the
code reference once, and call it directly:

    my $pull = \&$next;    # the iterator's code, found once
    while (my($value) = $pull->()) { ... }

Keep C<$next> while you use C<$pull>: the code reference doesn't keep
the iterator, and an iterator let go ends its run, after which C<$pull>
gives nothing. Over 300,000 values, this saves about 0.02 s.

=head2 An iterator as a source

An iterator can be given to another pipeline's
L<Ekorn::Pipeline/iterator> as its source, as it has an
L</EKORN_SOURCE> method. The values it hands out go through the second
pipeline's stages, and when the second run ends, it ends the first, so
its source is told. The second run's stages see the first run's
context, through L<Ekorn::Pipeline/run_context>.

An iterator is one run, so it can be a source only once, and only
before it has handed out everything it will.

=head1 METHODS

=head2 new

Iterators are made by L<Ekorn::Pipeline/iterator>, not by calling
C<new>.

=head2 all

    my @rest = $next->all;
    my $rest = $next->all;    # the same, as an array reference

Returns every value still to come, reading the run to its end. In
scalar context, it returns them as an array reference. Where values
are already waiting at the end of the stages, such as a sink of many's
result, or a step's many values, where there are no stages, it takes
them all at once, rather than one call at a time.

=head2 first

    my $first = $next->first;

Returns the next value, or C<undef> if there's none, and ends the run,
as L</finish> does, so nothing more is read.

=head2 single

    my $one = $next->single;

Returns the next value, or C<undef> if there's none, and ends the run,
as L</first> does. It pulls one value more first, to check there's no
other, and warns "Expected only one item, but there were more" if there
is.

=head2 finish

    $next->finish;

Ends the run now, if it hasn't ended: nothing more is read, and
nothing waiting is handed out. Each part's end is told how the run
ended from where it stands: C<stopped>, if its input hadn't run out.
Every call after returns an empty list.

=head2 ended

    my $how = $next->ended;

Returns how the run ended, once the iterator has handed out all it
will, been finished, or died; until then, nothing:

=over

=item * C<done> if the source was read to its end;

=item * C<stopped> if the reading was cut short, by a stop anywhere,
such as C<take(5)>'s, or by L</finish>, or if L</finish> dropped values
still to be handed out;

=item * C<died> if anything in the run died, an end included.

=back

It says how the run ended for whoever is reading it: each part's end
is told how it ended from where that part stands, which may differ.

=head2 EKORN_SOURCE

    my $parts = $next->EKORN_SOURCE;

Returns the iterator as a source's parts, by name, as L</An iterator as
a source> describes: a C<step> pulling it, an C<end> finishing it, and
its run's C<context>. A run calls it as it starts; you needn't.

=head1 DIAGNOSTICS

=over

=item Expected only one item, but there were more

A warning: L</single> found more than one value to come.

=item Expected a source with values still to give: an iterator is one run, and this one is spent

An iterator was given as a source after it had handed out everything
it will, been finished, or died.

=back

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Source>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
