use v5.36;

package Ekorn::Pipeline::Sources;

use Exporter                   qw(import);
use Scalar::Util               qw(looks_like_number openhandle);
use Ekorn::Pipeline::Errors    qw(croakf);
use Ekorn::Pipeline::Factories qw(source);
use namespace::clean -except => 'import';

our @EXPORT_OK   = qw(from_array from_fh from_file counter);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# Return a source giving the values given, from the first, each run.
sub from_array (@values) {
    return source {
        my $i = 0;
        return sub () { $i < @values ? $values[$i++] : () };
    };
}


# Return a source giving the filehandle's records, as $/ divides them,
# with $/ taken off, leaving it open, for its opener to close.
sub from_fh ($fh) {
    croakf 'Expected an open filehandle' unless defined openhandle($fh);
    return source { _records($fh) };
}


# Return a source giving the file's records, as $/ divides them, with $/
# taken off; the file is opened for each run, with the I/O layers given,
# if any, such as ':raw', and closed as it ends.
sub from_file ($path, $layers = '') {
    return source {
        # Open for the run, and closed by its end.
        open my $fh, "<$layers", $path or croakf    ## no critic (InputOutput::RequireBriefOpen)
            q(Can't read %s: %s), $path, $!;
        return {step => _records($fh), end => sub ($how) { close $fh }};
    };
}


# Return a source giving $start, then on by $step, without end.
sub counter ($start = 1, $step = 1) {
    croakf 'Expected a number to start from, and one to step by'
        unless looks_like_number($start) && looks_like_number($step);
    return source {
        my $next = $start;
        return sub () { my $n = $next; $next += $step; return $n };
    };
}


# Return a step reading the filehandle's records, as $/ divides them, at
# each read, with $/ taken off. With $/ undefined, what's left is one
# record, and an empty file none, where readline gives an empty string.
sub _records ($fh) {
    return sub () {
        my $read = readline $fh;
        return if !defined $read || (!defined $/ && $read eq '');
        chomp $read;
        return $read;
    };
}

1;

__END__

=encoding utf8

=head1 NAME

Ekorn::Pipeline::Sources - ready-made sources, needing only Perl

=head1 SYNOPSIS

    use Ekorn::Pipeline::Sources qw(from_array from_fh from_file counter);

    my $next = Ekorn::Pipeline->new(take(2))->iterator(from_file('tracks.txt'));
    # reads two lines, then closes the file

    my @evens = Ekorn::Pipeline->new(take(3))->iterator(counter(2, 2))->all;    # 2 4 6

=head1 DESCRIPTION

Sources for L<Ekorn::Pipeline/iterator>, needing nothing beyond Perl.
Each returns an L<Ekorn::Pipeline::Source>, made afresh for each run,
so each run reads from the start. Nothing is exported by default; ask
for each, or for C<:all>.

C<from_fh> and C<from_file> read with C<$/> as it is at each read, as
C<readline> does: lines, unless it's changed; a paragraph at a time,
with C<$/> set to C<''>; records of a fixed size, with a reference to
a number, as C<\4096>; and all of what's left as one record, slurped,
with C<$/> undefined, an empty file giving none, though C<readline>
gives one empty string. Each record is given without its separator, as
C<chomp> removes it.

=head1 FUNCTIONS

=head2 from_array

    from_array(@values)

Gives the values given, in order, from the first, on each run. A hash's
pairs are C<from_array(map { [$_, $hash{$_}] } keys %hash)>. It has no
end.

=head2 from_fh

    from_fh($fh)

Gives the records read from C<$fh>, a filehandle you opened, which it
leaves open, for you to close. Each run reads on from where the last
left off. It croaks "Expected an open filehandle" given anything else.

=head2 from_file

    from_file($path)
    from_file($path, $layers)

Gives the records of the file at C<$path>, opening it for each run,
and closing it once the run has ended, however it ended: when the
records ran out, when a stage stopped the run, or when one died. It's
opened through the I/O layers given, if any: C<':raw'> reads bytes,
unchanged on any platform, and C<':encoding(UTF-8)'> decodes text.
Without them, Perl opens it as it does by default, which on Windows
translates line endings, and so corrupts a binary file. A file that
can't be opened croaks "Can't read %s: %s" as the run starts.

=head2 counter

    counter($start, $step)
    counter()

Gives C<$start>, then on by C<$step>, without end: 1, 2, 3 and on, by
default. Give it a C<take>, or a stage that stops. It croaks
"Expected a number to start from, and one to step by" given anything
else.

=head1 DIAGNOSTICS

=over

=item Expected an open filehandle

L</from_fh> was given something other than an open filehandle.

=item Can't read %s: %s

L</from_file> couldn't open the file, as a run started; the second
part says why.

=item Expected a number to start from, and one to step by

L</counter> was given something other than numbers.

=back

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Source>,
L<Ekorn::Pipeline::Factories>, L<Ekorn::Pipeline::Sinks>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
