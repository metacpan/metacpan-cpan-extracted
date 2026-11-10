use v5.36;

package Ekorn::Pipeline::Stages::Flow;

use Exporter  qw(import);
use Ref::Util qw(is_coderef);

use Ekorn::Pipeline::Errors qw(croakf);
use Ekorn::Pipeline::Gather qw(gather);
use Ekorn::Pipeline::Stop   qw();

use namespace::clean -except => 'import';

our @EXPORT = qw(take drop);    ## no critic (Modules::ProhibitAutomaticExportation)

our @EXPORT_OK   = (@EXPORT, qw(take_while drop_while));
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

# Return a stage passing on values while the test given is true of them,
# and stopping the pipeline at the first it's false of.
sub take_while : prototype(&) ($test) {
    croakf 'Expected a code reference' unless is_coderef($test);
    return sub ($value) {
        return $value if $test->($value);
        Ekorn::Pipeline::Stop->throw;
    };
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

Ekorn::Pipeline::Stages::Flow - stages taking or dropping values: take, drop, take_while and drop_while

=head1 SYNOPSIS

    use Ekorn::Pipeline;
    use Ekorn::Pipeline::Stages::Flow;    # take and drop

    # The third page of ten
    my @page = Ekorn::Pipeline->new(drop(20), take(10))->(@names);

    use Ekorn::Pipeline::Stages::Flow qw(:DEFAULT take_while drop_while);

    # A mail's headers: its lines up to the first blank one
    my $headers = Ekorn::Pipeline->new(take_while { m( \S )x })
        ->iterator(sub { scalar(<$fh>) // () });

=head1 DESCRIPTION

Stages that decide which values go on, by their position or by a
test, whatever the values are. Each function returns a stage. It
checks its arguments when it's called, not on each value.

C<take>, C<drop> and C<drop_while> keep state, so they're made with
L<Ekorn::Pipeline::Gather> and start afresh on each run. A run is a
call of a pipeline with values, or an iterator made from it.

C<take> and C<take_while> end the pipeline with
L<Ekorn::Pipeline::Stop> once they've passed on all they will, so an
iterator stops calling its source.

=head1 FUNCTIONS

C<take> and C<drop> are exported by default. C<take_while> and
C<drop_while> are exported on request, and C<:all> gives all four. To
get the defaults and one more, name C<:DEFAULT> too:

    use Ekorn::Pipeline::Stages::Flow qw(:DEFAULT take_while);

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

=head2 take_while

    take_while { ... }

Passes on values while the block returns true for them, then stops the
pipeline at the first value it returns false for. That value isn't
passed on. The block gets each value in C<$_> and as its argument.

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

C<take_while> or C<drop_while> was given something other than a block
or code reference.

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
