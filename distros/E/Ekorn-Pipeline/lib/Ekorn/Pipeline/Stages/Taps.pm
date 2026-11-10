use v5.36;

package Ekorn::Pipeline::Stages::Taps;

use Data::Dumper qw();
use Exporter     qw(import);
use Ref::Util    qw(is_coderef is_plain_scalarref);
use Scalar::Util qw(openhandle);

use Ekorn::Pipeline::Errors qw(croakf);
use Ekorn::Pipeline::Gather qw(gather);

use namespace::clean -except => 'import';

our @EXPORT = qw(peek count_into);    ## no critic (Modules::ProhibitAutomaticExportation)

our @EXPORT_OK   = (@EXPORT, qw(dump_to));
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# Return a stage calling the block given with each value, for its side
# effects, and passing the value on.
sub peek : prototype(&) ($block) {
    croakf 'Expected a code reference' unless is_coderef($block);
    return sub ($value) {
        $block->($value);
        return $value;
    };
}

# Return a stage counting the values into the scalar given, from 0 on
# each run, and passing them on.
sub count_into ($count) {
    croakf 'Expected a reference to a scalar'
        unless is_plain_scalarref($count);
    return gather {
        $$count = 0;
        return sub ($value) {
            $$count++;
            return $value;
        };
    };
}

# Return a stage writing each value, with Data::Dumper, to the filehandle
# given, or STDERR, and passing it on.
sub dump_to ($fh = \*STDERR) {
    croakf 'Expected an open filehandle' unless defined openhandle($fh);
    return sub ($value) {
        local $Data::Dumper::Indent   = 1;
        local $Data::Dumper::Sortkeys = 1;
        local $Data::Dumper::Terse    = 1;
        print { $fh } Data::Dumper::Dumper($value);
        return $value;
    };
}

1;
__END__

=encoding utf8

=head1 NAME

Ekorn::Pipeline::Stages::Taps - stages run for their side effects: peek, count_into and dump_to

=head1 SYNOPSIS

    use Ekorn::Pipeline;
    use Ekorn::Pipeline::Stages::Taps;    # peek and count_into

    my $read = 0;
    my @names = Ekorn::Pipeline->new(
        count_into(\$read),                 # how many values were read
        peek { log_user($_) },              # each value, as it goes by
        sub { $_->{name} },
    )->(@users);

    use Ekorn::Pipeline::Stages::Taps qw(dump_to);

    Ekorn::Pipeline->new(dump_to)->(@users);    # to STDERR

=head1 DESCRIPTION

Stages that look at each value as it goes by and pass it on unchanged,
for logging, counting or debugging. A stage passes on what it returns,
so a stage of your own that runs for its side effects has to return
its value. These do that for you. Each function returns a stage, and
checks its arguments when it's called, not on each value.

They work wherever stages do: in any pipeline, or on an object with
C<pipe> and C<tap>, from L<Ekorn::Pipeline::Pipes>, where the first
value is the object:

    $client->tap(peek { say "connected to $_->{host}" })->run;

=head1 FUNCTIONS

C<peek> and C<count_into> are exported by default. C<dump_to> is
exported on request, and C<:all> gives all three.

=head2 peek

    peek { ... }

Calls the block with each value, in C<$_> and as its argument, and
passes the value on, whatever the block returns.

=head2 count_into

    count_into(\$count)

Counts the values into C<$count>. It sets C<$count> to 0 at the start
of each run, so after a run it holds how many values went by, even if
none did.

=head2 dump_to

    dump_to($fh)
    dump_to

Writes each value to C<$fh>, or to STDERR, with Data::Dumper, keys
sorted, and passes it on.

It's for debugging. It writes each value in full, secrets and all. It
doesn't escape control characters in strings, so a value from outside
can send escape sequences to a terminal.

=head1 DIAGNOSTICS

=over

=item Expected a code reference

C<peek> was given something other than a block or code reference.

=item Expected a reference to a scalar

C<count_into> was given something other than a reference to a scalar.

=item Expected an open filehandle

C<dump_to> was given something other than an open filehandle.

=back

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Gather>, L<Data::Dumper>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
