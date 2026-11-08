use v5.36;

package Ekorn::Pipeline::Stages::Batch;

use Exporter  qw(import);
use Ref::Util qw(is_coderef);

use Ekorn::Pipeline::Errors qw(croakf);
use Ekorn::Pipeline::Gather qw(gather);

use namespace::clean -except => 'import';

our @EXPORT = qw(batch collect);    ## no critic (Modules::ProhibitAutomaticExportation)

our @EXPORT_OK   = @EXPORT;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# Return a stage passing values on in batches of $size, as array
# references, the last, shorter batch once the values run out.
sub batch ($size) {
    croakf 'Expected a batch size of 1 or more'
        if !defined $size || $size !~ m( \A \d+ \z )xa || $size < 1;
    return gather {
        my @batch;
        my $stage = sub ($value) {
            push @batch, $value;
            return @batch < $size ? () : [splice @batch];
        };
        my $end = sub () { @batch ? [splice @batch] : () };
        return ($stage, $end);
    };
}

# Return a stage holding every value, and, once they run out, passing on
# what the block given makes of them, or, without one, an array of them.
sub collect : prototype(;&) ($make = undef) {
    croakf 'Expected a code reference'
        if defined $make && !is_coderef($make);
    return gather {
        my @values;
        my $stage = sub ($value) { push @values, $value; return };
        my $end   = sub () {
            my @all = splice @values;
            return $make ? $make->(@all) : \@all;
        };
        return ($stage, $end);
    };
}

1;
__END__

=encoding utf8

=head1 NAME

Ekorn::Pipeline::Stages::Batch - stages gathering values: batch and collect

=head1 SYNOPSIS

    use Ekorn::Pipeline;
    use Ekorn::Pipeline::Stages::Batch;    # batch and collect

    # Values 500 at a time
    my $batches = Ekorn::Pipeline->new(batch(500))->iterator($source);
    while (my($batch) = $batches->()) { ... }

    # Every value, as one result
    my($all) = Ekorn::Pipeline->new(collect)->(@values);

    # One value made from every value
    my($names) = Ekorn::Pipeline->new(
        sub { $_->{name} },
        collect { join ', ', @_ },
    )->(@users);

=head1 DESCRIPTION

Stages that gather values, and pass them on together. Both are made
with L<Ekorn::Pipeline::Gather>, so what they hold starts afresh on each
run, and both pass on what they still hold once the values run out.
Each function returns a stage, and checks what it's given when it's
called, not on each value.

=head1 FUNCTIONS

Both are exported by default, and with C<:all>.

=head2 batch

    batch($size)

Passes values on in batches of C<$size>, each an array reference. Once
the values run out, the last batch, which may be shorter, goes on.
There's no empty batch: without values, there's no batch at all.

=head2 collect

    collect
    collect { ... }

Holds every value, and once they run out, passes on an array reference
of them, or, given a block, what the block returns, called once with
the values as its arguments. What it returns goes through the stages
after it, as what a stage returns does: nothing, one value, or several.
It's called even without values, so C<collect> still gives a result:
an empty array, or what the block makes of none.

C<collect> holds every value until the end, so the whole result is in
memory at once; C<batch> holds no more than one batch.

=head1 DIAGNOSTICS

=over

=item Expected a batch size of 1 or more

C<batch> was given something other than a whole number above 0.

=item Expected a code reference

C<collect> was given something other than a block or code reference.

=back

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Gather>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
