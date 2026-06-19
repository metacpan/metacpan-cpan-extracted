package JSON::JSONFold::Stats;

1;

__END__

=head1 NAME

JSON::JSONFold::Stats - formatting statistics for JSON::JSONFold

=head1 SYNOPSIS

    use JSON::JSONFold;

    my $stats = write_json(
        $data,
        \*STDOUT,
        100,
        'default'
    );

    printf(
        "Input bytes:  %d\nOutput bytes: %d\nReduction: %.1f%%\n",
        $stats->bytes_in,
        $stats->bytes_out,
        100 * (1 - $stats->bytes_out / $stats->bytes_in)
    );

=head1 DESCRIPTION

C<JSON::JSONFold::Stats> stores statistics collected during formatting.

Statistics are available from C<write_json>, C<JSON::JSONFold::write>, and
C<JSON::JSONFold::Writer::stats>.

=head1 METHODS

=head2 bytes_in

    my $bytes = $stats->bytes_in;

Returns the number of input bytes processed.

=head2 bytes_out

    my $bytes = $stats->bytes_out;

Returns the number of output bytes generated.

=head2 lines_in

    my $lines = $stats->lines_in;

Returns the number of input lines processed.

=head2 lines_out

    my $lines = $stats->lines_out;

Returns the number of output lines generated.

=head2 reset

    $stats->reset;

Reset all counters to zero.

=head1 EXAMPLE

    my $stats = write_json(
        $data,
        \*STDOUT,
        100,
        'default'
    );

    printf "Bytes: %d -> %d\n",
        $stats->bytes_in,
        $stats->bytes_out;

    printf "Lines: %d -> %d\n",
        $stats->lines_in,
        $stats->lines_out;

=head1 SEE ALSO

L<JSON::JSONFold>,
L<JSON::JSONFold::Writer>

=head1 AUTHOR

Yair Lenga

=head1 COPYRIGHT AND LICENSE

See the distribution license.

=cut