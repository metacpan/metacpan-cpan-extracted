use v5.36;

package Ekorn::Pipeline::Sinks;

use Carp                    qw();
use Exporter                qw(import);
use Scalar::Util            qw(openhandle);
use Ekorn::Pipeline::Errors qw(croakf);
use Ekorn::Pipeline::Sink   qw();
use Ekorn::Pipeline::Stop   qw();
use namespace::clean -except => 'import';

our @EXPORT_OK = qw(
    keep  keep_all count_items keep_first keep_last keep_single
    to_fh to_file);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# Each sink taking no arguments has an empty prototype, so that
# `count_items + 0` reads as `count_items() + 0`, not `count_items(+0)`.
# A chain inside a larger expression still needs parentheses, as |
# binds loosest.

# Return a sink giving how many values there were.
sub count_items : prototype() () {
    return Ekorn::Pipeline::Sink->new_sink_one(sub {
        my $n = 0;
        return {step => sub ($value) { $n++ }, flush => sub () { $n }};
    });
}


# The sinks named for what they give: keep_all, keep(N), keep_first,
# keep_last, keep_single and count_items. The container sinks, named for
# where the items go, are to_fh and to_file, below.

# Return a sink giving every item, as a list.
sub keep_all : prototype() () {
    return Ekorn::Pipeline::Sink->new_sink_many(sub {
        my @all;
        return {step => sub ($item) { push @all, $item }, flush => sub () { @all }};
    });
}


# Return a sink giving the one item, asserting it's the only one: at a
# second, it warns and stops the run, giving the first; undef if there
# was none.
sub keep_single : prototype() () {
    return Ekorn::Pipeline::Sink->new_sink_one(sub {
        my @only;
        return {
            step => sub ($item) {
                if (@only) {
                    Carp::carp 'Expected only one item, but there were more';
                    Ekorn::Pipeline::Stop->throw;
                }
                @only = ($item);
                return;
            },
            flush => sub () { @only },
        };
    });
}


# Return a sink giving the first item, stopping the run there; undef if
# there was none.
sub keep_first : prototype() () {
    return Ekorn::Pipeline::Sink->new_sink_one(sub {
        my @first;
        return {
            step  => sub ($value) { @first = ($value); Ekorn::Pipeline::Stop->throw },
            flush => sub () { @first },
        };
    });
}


# Return a sink giving the first $count items, as a list, stopping the
# run once it has them.
sub keep ($count) {
    croakf 'Expected a count of 0 or more'
        unless defined $count && $count =~ m( \A \d+ \z )xa;
    return Ekorn::Pipeline::Sink->new_sink_many(sub {
        my @kept;
        return {
            step => sub ($item) {
                Ekorn::Pipeline::Stop->throw if @kept >= $count;
                push @kept, $item;
                Ekorn::Pipeline::Stop->throw if @kept >= $count;
                return;
            },
            flush => sub () { @kept },
        };
    });
}


# Return a sink giving the last item, reading every one to find it;
# undef if there was none.
sub keep_last : prototype() () {
    return Ekorn::Pipeline::Sink->new_sink_one(sub {
        my @kept;
        return {
            step  => sub ($item) { @kept = ($item); return },
            flush => sub () { @kept },
        };
    });
}


# Return a sink printing each value to the filehandle given, followed by
# $/, giving how many, and leaving it open, for its opener to close.
sub to_fh ($fh) {
    croakf 'Expected an open filehandle' unless defined openhandle($fh);
    return Ekorn::Pipeline::Sink->new_sink_one(sub {
        return _writer($fh, 'the filehandle');
    });
}


# Return a sink writing each value to the file, followed by $/, giving
# how many; the file is opened as the run starts, with the I/O layers
# given, if any, such as ':raw', and closed as it ends.
sub to_file ($path, $layers = '') {
    return Ekorn::Pipeline::Sink->new_sink_one(sub {
        # Open for the run, and closed by its end.
        open my $fh, ">$layers", $path    ## no critic (InputOutput::RequireBriefOpen)
            or croakf q(Can't write %s: %s), $path, $!;
        return {
            %{ _writer($fh, $path) },
            end => sub ($how) { close $fh or croakf q(Can't write %s: %s), $path, $! },
        };
    });
}


# Return, by name, the step and the flush of a sink printing each value to $fh,
# named $what in its message, followed by $/ as it is now, as from_fh and
# from_file take it off: nothing if it's undefined or a record's size,
# and a blank line, for paragraph mode, if it's empty. The flush gives
# how many.
sub _writer ($fh, $what) {
    my $after = ref $/ || !defined $/ ? '' : length $/ ? $/ : "\n\n";
    my $n     = 0;
    return {
        step => sub ($value) {
            print { $fh } $value, $after or croakf q(Can't write %s: %s), $what, $!;
            $n++;
        },
        flush => sub () { $n },
    };
}

1;

__END__

=encoding utf8

=head1 NAME

Ekorn::Pipeline::Sinks - ready-made sinks, needing only Perl

=head1 SYNOPSIS

    use Ekorn::Pipeline::Sinks qw(:all);

    my @all   = Ekorn::Pipeline->new(keep_all)->(@values);          # every value
    my $all   = Ekorn::Pipeline->new(keep_all)->(@values);          # the same, as an array reference
    my $n     = Ekorn::Pipeline->new(count_items)->(@values);       # how many
    my $first = Ekorn::Pipeline->new(keep_first)->iterator($source)->();    # stops at the first

    my $copied = Ekorn::Pipeline->new(to_file('copy.txt'))->iterator(from_file('original.txt'))->();

=head1 DESCRIPTION

Sinks, each usually given last in a pipeline, so that its result is
what a run gives (see L<Ekorn::Pipeline::Sink>). Each is made afresh
for each run. Nothing is exported by default; ask for each, or for
C<:all>.

They come in two families. Those named for what they give, an item
being a value, have names that can't clash with Perl's built-ins or
List::Util's, which is why they're C<keep_first> and C<keep_all>, not
C<first> and C<all>. The containers, named for where the items go, are
the C<to_> sinks, each the counterpart of a C<from_> source in
L<Ekorn::Pipeline::Sources>: what one reads, the other writes.

Asked for one value, in scalar context, a sink giving a list gives it
as an array reference. An array reference is true even when it's
empty, so test for no items with C<@$all>, or use C<count_items>.

A sink that stops the pull early is told C<done>: it decided the run
had enough. The source and the stages before it are told C<stopped>.

Each sink taking no arguments has an empty prototype, so that
C<count_items + 0> reads as C<count_items() + 0>.

=head1 FUNCTIONS

=head2 keep_all

Gives every item, as a list. It's a sink of many.

=head2 keep

    keep($n)

Gives the first C<$n> items, as a list, as C<take($n)> would pass on,
and stops the run once it has them. It's a sink of many. It croaks
"Expected a count of 0 or more", as C<take> does, given anything but a
whole number.

=head2 keep_first

Gives the first item, or C<undef> if there was none, and stops the run
there.

=head2 keep_single

Gives the one item, or C<undef> if there was none. At a second, it
warns "Expected only one item, but there were more", and stops the
run, giving the first: for when you meant one item, and forgot to limit
it to one.

=head2 keep_last

Gives the last item, reading every one to find it, or C<undef> if there
was none.

=head2 count_items

Gives how many items there were.

=head2 to_fh

    to_fh($fh)

Prints each item to C<$fh>, a filehandle you opened, followed by C<$/>,
and gives how many. It leaves the filehandle open, for you to close. It
croaks "Expected an open filehandle" given anything else.

=head2 to_file

    to_file($path)
    to_file($path, $layers)

Writes each item to the file at C<$path>, followed by C<$/>, and gives
how many. The file is opened, emptied, as the run starts, through the
I/O layers given, if any, such as C<':raw'> or C<':encoding(UTF-8)'>,
and closed once the run has ended, however it ended.

C<from_fh> and C<from_file> take C<$/> off each record, and C<to_fh> and
C<to_file> add it back, so a file read with one is written unchanged by
the other. With C<$/> undefined, or a reference to a record size,
nothing is added; with it empty, for paragraphs, a blank line is.

=head1 DIAGNOSTICS

=over

=item Expected a count of 0 or more

L</keep> was given something other than a whole number.

=item Expected only one item, but there were more

A warning: L</keep_single> was given a second item, and stopped the
run, giving the first.

=item Expected an open filehandle

L</to_fh> was given something other than an open filehandle.

=item Can't write %s: %s

L</to_fh> or L</to_file> couldn't write, or L</to_file> couldn't open
or close its file; the second part says why. The first is the file's
path, or "the filehandle".

=back

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Sink>,
L<Ekorn::Pipeline::Sources>, L<Ekorn::Pipeline::Stages::Flow>, whose
C<take> stages match the C<keep> sinks

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
