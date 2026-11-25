use v5.36;

package Ekorn::Pipeline::Feed;

use Ekorn::Pipeline::Errors qw(croakf);
use namespace::clean;

# Croak at the line that called Ekorn::Pipeline.
our $VERSION = 'v0.4.0';

our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# Return a feed of a run, from its parts, each a code reference: push,
# taking values and returning what came out of them; close, ending the
# input and returning what the flushes give; finish, ending the run as
# from outside; and ended, returning how the run ended, or nothing
# while it's open.
sub new ($class, %parts) {
    return bless {%parts, why => undef, busy => 0}, $class;
}

# Return what came out of the values pushed: a list, or, asked for one
# value, an array reference of them.
#
# Checked inline, as a feed may be pushed a value at a time. A push that
# dies leaves busy set, but the run has died, which is checked first.
sub push ($self, @values) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    $self->_check_open('push') if $self->{busy} || defined $self->{ended}->();
    $self->{busy} = 1;
    my @results = $self->{push}->(@values);
    $self->{busy} = 0;
    return wantarray ? @results : \@results;
}

# End the input, and return what the flushes give, as push returns its
# results.
sub close ($self) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms, NamingConventions::ProhibitAmbiguousNames)
    $self->_check_open('close');
    $self->{busy} = 1;
    my @results = $self->{close}->();
    @$self{qw(busy why)} = (0, 'it was closed');
    return wantarray ? @results : \@results;
}

# End the run, if it hasn't ended, as from outside.
sub finish ($self) {
    return if defined $self->ended;
    croakf 'Expected no %s of a feed from inside its own run', 'finish'
        if $self->{busy};
    $self->{finish}->();
    $self->{why} = 'it was finished';
    return;
}

# Return how the run ended: "done", "stopped" or "died"; nothing while
# it's open.
sub ended ($self) {
    return $self->{ended}->();
}

# Croak unless the run is open, and the call isn't from inside it: once
# the run has ended, busy may be left set by a push that died.
sub _check_open ($self, $method) {
    my $ended = $self->ended;
    croakf 'Expected a feed still open, but its run has ended: %s',
        $self->{why} // ($ended eq 'died' ? 'it died' : 'a stage stopped it')
        if defined $ended;
    croakf 'Expected no %s of a feed from inside its own run', $method
        if $self->{busy};
    return;
}

1;
__END__

=encoding utf8

=head1 NAME

Ekorn::Pipeline::Feed - one run, fed values as they arrive

=head1 SYNOPSIS

    use Ekorn::Pipeline;

    my $feed = Ekorn::Pipeline->new(@stages)->feed;

    # Wherever values arrive: a library's callback, an event, a stage
    for my $value (@values) {
        my @results = $feed->push($value);    # what came out of it
        last if defined $feed->ended;         # a stage stopped the run
    }
    my @rest = $feed->close unless defined $feed->ended;    # the flushes'

=head1 DESCRIPTION

A feed is one run of a pipeline's stages, which you give values as
they arrive, rather than all at once, as a pushed run takes them, or
when a result is wanted, as an iterator asks its source. It's made by
L<Ekorn::Pipeline/feed>, not by calling C<new>.

Each L</push> runs its values through the stages, and returns what
came out of them, there and then. L</close> says no more values are
coming: the flushes are called, and what they give is returned, and
then the ends. Between the two, the run goes on as a run does, with
its C<gather> stages' state kept from one push to the next, so
C<take(5)> takes five values from all that are pushed, and C<batch(3)>
fills its batches across pushes. Fed the same values, a feed gives
what C<< $pipeline->(@values) >> gives, in the same order, but a push
at a time.

That's what makes it possible to run a pipeline where the values don't
come from you:

=over

=item * B<A library that calls you back,> for each row, record, line
or file it finds, or an event loop, for each message. The callback
pushes, and when a stage has stopped the run, as C<take> does, it
tells the library to stop.

=item * B<A stage with a branch of its own:> a stage made with
L<Ekorn::Pipeline::Gather> can make a feed for each run, and push its
values into another pipeline, closing it in its flush and finishing it
in its end. A tee, running each value through a branch of stages for
their side effects and passing it on unchanged, is one; a stage
running each key's values through a run of its own is another. The
user guide, L<Ekorn::Pipeline::Manual::HowTo>, builds both.

=item * B<A writer> that's given values as a program makes them, and
batches, counts or commits them through stages, its flushes and ends
seeing the run through however it ends.

=back

=head2 How a feed ends

A feed's run ends in one of four ways, and L</ended> says how, once it
has:

=over

=item * L</close>: the flushes are called, then the ends, each told
C<done>, or C<stopped> if a flush's stop cut its input short.
C<ended> gives C<done>: the input was read to its end, as an
iterator's C<ended> says once its source has run out.

=item * A stop, from a stage, a flush or a sink, such as C<take>'s:
it ends the run in the push that meets it. The values it carries go
on, the flushes of the stages after it are called, then every end, and
that push returns all of it. C<ended> gives C<stopped>.

=item * A stage, a flush or an end that dies: the push or close dies
with it, named as a run names it, and each end is told C<died>.
C<ended> gives C<died>.

=item * L</finish>, or letting the feed go: no flush is called, and
each end is told C<stopped>, or C<done> if its input had run out.
C<ended> gives C<stopped>.

=back

Once the run has ended, however it ended, a push or a close croaks,
so values can't go nowhere unnoticed. So a caller feeding values as
they arrive asks C<ended> after each push, and stops when it's
defined.

A feed has no context of its own. Its stages and ends see the context
of the code pushing into it, through L<Ekorn::Pipeline/run_context>:
none, pushed from outside any run, or, pushed from a stage, that
stage's run's, such as a statement's columns. So a stage that feeds a
branch passes its run's context on to it. A push, a close or a finish from
inside the feed's own run, such as from one of its stages, croaks: a
stage can push into another pipeline's feed, but not its own.

=head1 METHODS

=head2 new

Feeds are made by L<Ekorn::Pipeline/feed>, not by calling C<new>.

=head2 push

    my @results = $feed->push(@values);
    my $results = $feed->push(@values);    # the same, as an array reference

Runs C<@values> through the stages, each through every stage before
the next, and returns what came out of them, in order: a list, or, in
scalar context, an array reference. A value a stage drops gives
nothing, and one a stage turns into several gives them all. A value
held back, as C<batch> holds values, comes out of a later push, or of
L</close>. A sink's result isn't among them: L</close> gives it.

If a stage stops the run, the push returns what came out before the
stop, the values the stop carried, through the stages after it, and
what the flushes after it give; the values after the one that met the
stop are dropped. If a stage dies, the push dies with it.

=head2 close

    my @rest = $feed->close;
    my $rest = $feed->close;    # the same, as an array reference

Ends the input, as a source running out does: calls the flushes, in
order, and returns what they give, through the stages after them, and
a sink's result, in a list, or, in scalar context, an array reference,
as an iterator's C<all> does at the end of its run. Then the ends are
called.

=head2 finish

    $feed->finish;

Ends the run now, as from outside, if it hasn't ended: nothing waiting
goes on, no flush is called, and each end is told how the run ended
from where it stands: C<stopped>, if its input hadn't run out. After a
run has ended, it does nothing. A feed let go before it's closed is
finished as the last reference to it goes, as an iterator let go is.

=head2 ended

    my $how = $feed->ended;

Returns how the run ended: C<done>, C<stopped> or C<died>, as
L</How a feed ends> describes; while it's open, nothing.

=head1 DIAGNOSTICS

=over

=item Expected a feed still open, but its run has ended: %s

A L</push> or L</close> came after the feed's run had ended, for the
reason given: it was closed; it was finished; a stage stopped it; or it
died. Ask L</ended> after each push, and stop pushing once it's
defined.

=item Expected no %s of a feed from inside its own run

A L</push>, L</close> or L</finish> was called from inside the feed's
own run: from one of its stages, flushes or ends. It's reported as
that stage's error.

=back

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Iterator>,
L<Ekorn::Pipeline::Gather>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
