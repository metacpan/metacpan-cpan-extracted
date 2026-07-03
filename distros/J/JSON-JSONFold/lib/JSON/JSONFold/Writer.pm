package JSON::JSONFold::Writer;
use strict ;

1;

__END__

=head1 NAME

JSON::JSONFold::Writer - streaming formatter for JSON::JSONFold

=head1 SYNOPSIS

    use JSON::JSONFold;

    my $formatter = create_formatter(
        \*STDOUT,
        100,
        'default'
    );

    $formatter->write("{\n");
    $formatter->write(qq(  "name": "Alice"\n));
    $formatter->write("}\n");

    $formatter->finish;
    $formatter->flush;

=head1 DESCRIPTION

C<JSON::JSONFold::Writer> incrementally processes pretty-printed JSON text and
writes a folded representation to an underlying filehandle.

This allows JSONFold to be used as a streaming post-processor without
buffering the entire document in memory.

Normally users should prefer the higher-level interfaces in
L<JSON::JSONFold>, such as C<format_json>, C<write_json>, or the object
interface.

=head1 CONSTRUCTOR

=head2 new

    my $formatter = JSON::JSONFold::Writer->new(
        $fh,
        $config,
        $close_fp
    );

Creates a streaming formatter around an existing filehandle.

Parameters:

=over

=item * C<$fh>

Destination filehandle.

=item * C<$config>

JSONFold configuration object.

=item * C<$close_fp>

If true, closing the formatter also closes the underlying filehandle.

=back

=head1 METHODS

=head2 write

    $formatter->write($text);

Process additional pretty-printed JSON text.

The input may be supplied incrementally. Output is written to the underlying
filehandle as complete lines become available.

=head2 finish

    $formatter->finish;

Complete processing and emit any buffered output.

This method should be called after the last input has been written.

=head2 flush

    $formatter->flush;

Flush any pending output to the underlying filehandle.

=head2 close

    $formatter->close;

Close the formatter.

If the formatter was created with C<$close_fp> set to true, the underlying
filehandle is also closed.

=head2 stats

    my $stats = $formatter->stats;

Return a L<JSON::JSONFold::Stats> object containing formatting statistics.

=head2 reset

    $formatter->reset;

Reset the formatter state and statistics.

=head1 EXAMPLE

    use JSON::JSONFold;

    my $formatter = create_formatter(
        \*STDOUT,
        100,
        'default'
    );

    my $json = JSON->new->pretty;

    $formatter->write(
        $json->encode($data)
    );

    $formatter->finish;
    $formatter->close;

=head1 SEE ALSO

L<JSON::JSONFold>,
L<JSON::JSONFold::Config>,
L<JSON::JSONFold::Stats>

=head1 AUTHOR

Yair Lenga

=head1 COPYRIGHT AND LICENSE

See the distribution license.

=cut