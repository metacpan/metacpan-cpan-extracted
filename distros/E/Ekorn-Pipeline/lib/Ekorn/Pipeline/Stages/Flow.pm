use v5.36;

package Ekorn::Pipeline::Stages::Flow;

use Carp      qw();
use Exporter  qw(import);
use Ref::Util qw(is_coderef);

use Ekorn::Pipeline::Errors qw(croakf);
use Ekorn::Pipeline::Gather qw(gather);
use Ekorn::Pipeline::Stage  qw();
use Ekorn::Pipeline::Stop   qw();

use namespace::clean -except => 'import';

our @EXPORT = qw(take drop);    ## no critic (Modules::ProhibitAutomaticExportation)

our @EXPORT_OK = (
    @EXPORT,
    qw(take_first take_last take_single take_while drop_while take_if drop_if),
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# Return a stage passing on the first $count values, then stopping the
# pipeline, so nothing after them is fetched.
sub take ($count) {
    _check_count($count);
    return gather {
        my $taken = 0;
        return sub ($value) {
            Ekorn::Pipeline::Stop->throw if $taken >= $count;
            return ++$taken < $count ? $value : Ekorn::Pipeline::Stop->throw($value);
        };
    };
}

# Return a stage dropping the first $count values, and passing on the
# rest.
sub drop ($count) {
    _check_count($count);
    return gather {
        my $dropped = 0;
        return sub ($value) {
            return $value if $dropped >= $count;
            $dropped++;
            return;
        };
    };
}

# Return a stage passing on the first value, then stopping the
# pipeline: take(1), named as keep_first's analogue.
sub take_first : prototype() () {
    return take(1);
}


# Return a stage holding each value, and passing on the last once they
# run out; nothing if there were none.
sub take_last : prototype() () {
    return gather {
        my @kept;
        return {
            step  => sub ($value) { @kept = ($value); return },
            flush => sub () { splice @kept },
        };
    };
}


# Return a stage passing on the one value, asserting it's the only one:
# at a second, it warns and stops the pipeline.
sub take_single : prototype() () {
    return gather {
        my $seen = 0;
        return sub ($value) {
            return $value unless $seen++;
            Carp::carp 'Expected only one item, but there were more';
            Ekorn::Pipeline::Stop->throw;
        };
    };
}


# Return a stage passing on each value the test given is true of, and
# dropping the rest.
sub take_if : prototype(&) ($test) {
    croakf 'Expected a code reference' unless is_coderef($test);
    return Ekorn::Pipeline::Stage->new(
        sub ($value) { $test->($value) ? $value : () });
}


# Return a stage dropping each value the test given is true of, and
# passing on the rest.
sub drop_if : prototype(&) ($test) {
    croakf 'Expected a code reference' unless is_coderef($test);
    return Ekorn::Pipeline::Stage->new(
        sub ($value) { $test->($value) ? () : $value });
}


# Return a stage passing on values while the test given is true of them,
# and stopping the pipeline at the first it's false of.
sub take_while : prototype(&) ($test) {
    croakf 'Expected a code reference' unless is_coderef($test);
    return Ekorn::Pipeline::Stage->new(sub ($value) {
        return $value if $test->($value);
        Ekorn::Pipeline::Stop->throw;
    });
}

# Return a stage dropping values while the test given is true of them,
# and passing on the rest, from the first it's false of.
sub drop_while : prototype(&) ($test) {
    croakf 'Expected a code reference' unless is_coderef($test);
    return gather {
        my $dropping = 1;
        return sub ($value) {
            $dropping &&= !!$test->($value);
            return $dropping ? () : $value;
        };
    };
}


sub _check_count ($count) {
    croakf 'Expected a count of 0 or more'
        unless defined $count && $count =~ m( \A \d+ \z )xa;
    return;
}

1;
__END__

=encoding utf8

=head1 NAME

Ekorn::Pipeline::Stages::Flow - stages taking or dropping values: take, drop, take_if, drop_if, take_while and drop_while

=head1 SYNOPSIS

    use Ekorn::Pipeline;
    use Ekorn::Pipeline::Stages::Flow;    # take and drop

    # The third page of ten
    my @page = Ekorn::Pipeline->new(
        drop(20),
        take(10),
    )->(@names);

    use Ekorn::Pipeline::Stages::Flow qw(:DEFAULT take_while drop_while);

    # A mail's headers: its lines up to the first blank one
    my $headers = Ekorn::Pipeline->new(take_while { m( \S )x })
        ->iterator(sub { scalar(<$fh>) // () });

=head1 DESCRIPTION

Stages that decide which values go on, by their position or by a
test, whatever the values are. Each function returns a stage. It
checks its arguments when it's called, not on each value.

Each stage is an object, an L<Ekorn::Pipeline::Stage> or, for those
that keep state, an L<Ekorn::Pipeline::Gather>, called as a code
reference, so it goes wherever a stage goes. Code testing it with
C<ref> or C<is_coderef> sees an object: v0.2.0 gave code references.

C<take>, C<drop>, C<take_last>, C<take_single> and C<drop_while> keep
state, so they're made with L<Ekorn::Pipeline::Gather> and start
afresh on each run. A run is a call of a pipeline with values, or an
iterator made from it.

C<take_if> and C<drop_if> test every value; C<take_while> and
C<drop_while> stop testing at the first value the test fails, one by
ending the pipeline there, the other by passing on everything after.

C<take>, C<take_first>, C<take_single> and C<take_while> end the
pipeline with L<Ekorn::Pipeline::Stop> once they've passed on all they
will, so an iterator stops calling its source.

=head1 FUNCTIONS

C<take> and C<drop> are exported by default. C<take_first>,
C<take_last>, C<take_single>, C<take_if>, C<drop_if>, C<take_while> and
C<drop_while> are exported on request, and C<:all> gives all nine. To
get the defaults and one more, name C<:DEFAULT> too:

    use Ekorn::Pipeline::Stages::Flow qw(:DEFAULT take_if);

=head2 take

    take($count)

Passes on the first C<$count> values, then stops the pipeline. If there
are fewer, it passes them all on. C<take(0)> passes on none, but it
still sees the first value, because a stage isn't called until there
is one.

=head2 drop

    drop($count)

Drops the first C<$count> values, and passes on the rest. With
C<take>, it gives a page:

    drop(20), take(10)    # the 21st to the 30th

=head2 take_first

    take_first

Passes on the first value, then stops the pipeline: C<take(1)>, named
as the stage of the sink C<keep_first>.

=head2 take_last

    take_last

Passes on the last value, once there are no more, reading every one to
find it; nothing if there were none. If a stage before it stops the
pipeline, it passes on the last value to reach it.

Each C<take_...> stage passes on what the C<keep_...> sink of the same
name, in L<Ekorn::Pipeline::Sinks>, gives as its result, so the stages
after it can go on: C<take($n)> is C<keep($n)>'s, and C<take_first>,
C<take_last> and C<take_single> are C<keep_first>'s, C<keep_last>'s
and C<keep_single>'s. C<keep_all> has none, as its stage would pass
every value on, and be no stage at all. A pipeline ending in a C<take>
stage, where its sink was forgotten, gives the values in list context,
and how many in scalar context, never a wrong one.

=head2 take_single

    take_single

Passes on the one value. At a second, it warns "Expected only one item,
but there were more" and stops the pipeline, so the first is all that
goes on: for when one value was meant, and its limit forgotten.

=head2 take_if

    take_if { ... }

Passes on each value the block returns true for, and drops the rest:
a filter, as C<grep> is, testing every value. The block gets each
value in C<$_> and as its argument. It's new in v0.3.0.

    take_if { $_->{plays} >= 6000 }    # every hit

A plain stage ending in a test, C<sub { $_->{plays} >= 6000 }>, passes
on what the test returns, true or false, not the value; C<take_if>
passes on the value.

=head2 drop_if

    drop_if { ... }

Drops each value the block returns true for, and passes on the rest:
C<take_if>'s opposite. The block gets each value in C<$_> and as its
argument. It's new in v0.3.0.

=head2 take_while

    take_while { ... }

Passes on values while the block returns true for them, then stops the
pipeline at the first value it returns false for. That value isn't
passed on. The block gets each value in C<$_> and as its argument.
Unlike C<take_if>, it tests no value after the first that fails, so it
reads no further.

=head2 drop_while

    drop_while { ... }

Drops values while the block returns true for them, then passes on the
rest, starting with the first value it returns false for. After that,
the block isn't called again on that run. The block gets each value in
C<$_> and as its argument.

=head1 DIAGNOSTICS

=over

=item Expected a count of 0 or more

C<take> or C<drop> was given something other than a whole number.

=item Expected a code reference

C<take_if>, C<drop_if>, C<take_while> or C<drop_while> was given
something other than a block or code reference.

=item Expected only one item, but there were more

A warning: C<take_single> was given a second value, and stopped the
pipeline, passing on only the first.

=back

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Gather>, L<Ekorn::Pipeline::Stop>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
