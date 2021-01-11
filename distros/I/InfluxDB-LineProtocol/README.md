# NAME

InfluxDB::LineProtocol - Write and read InfluxDB LineProtocol

# VERSION

version 1.014

# SYNOPSIS

    use InfluxDB::LineProtocol qw(data2line line2data);

    # convert some Perl data into InfluxDB LineProtocol
    my $influx_line = data2line('measurement', 42);
    my $influx_line = data2line('measurement', { cost => 42 });
    my $influx_line = data2line('measurement', 42, { tag => 'foo'} );

    # convert InfluxDB Line back into Perl
    my ($measurement, $values, $tags, $timestamp) =
      line2data("metric,location=eu,server=srv1 value=42 1437072299900001000");

# DESCRIPTION

[InfluxDB](https://influxdb.com) is a rather new time series database.
Since version 0.9 they use their
[LineProtocol](https://influxdb.com/docs/v0.9/write_protocols/line.html)
to write time series data into the database. This module allows you to
generate such a line from a datastructure, handling all the annoying
escaping and sorting for you. You can also use it to parse a line
(maybe you want to add some tags to a line written by another app).

Please read the InfluxDB docs so you understand how metrics, values
and tags work.

`InfluxDB::LineProtocol` will always try to implement the most
current version of the InfluxDB line protocol, while allowing you to
also get the old behaviour. Currently we support `0.9.3` and newer
per default, and `0.9.2` if you ask nicely.

## FUNCTIONS

### data2line

    data2line($metric, $single_value);
    data2line($metric, $values_hashref);
    data2line($metric, $value, $tags_hashref);
    data2line($metric, $value, $nanoseconds);
    data2line($metric, $value, $tags_hashref, $nanoseconds);

`data2line` takes various parameters and converts them to an
InfluxDB Line.

`metric` has to be valid InfluxDB measurement name. Required.

`value` can be either a scalar, which will be turned into
"value=$value"; or a hashref, if you want to write several values (or
a value with another name than "value"). Required.

`tags_hashref` is an optional hashref of tag-names and tag-values.

`nanoseconds` is an optional integer representing nanoseconds since
the epoch. If you do not pass it, `InfluxDB::LineProtocol` will use
`Time::HiRes` to get the current timestamp.

### line2data

    my ($metric, $value_hashref, $tags_hashref, $timestamp) = line2data( $line );

`line2data` parses an InfluxDB line and always returns 4 values.

`tags_hashref` is undef if there are no tags!

# PRECISION

InfluxDB support different timestamp precisions:

Nanosecond (ns, the default), microseconds (us), milliseconds (ms),
seconds (s), minutes (m) and hours (h). If you do not want to generate
lines using nanoseconds (which might be a good idea, because InfluxDB
uses less space and has better performance if you choose a smaller
precision), you can specify the wanted precision on load of
`InfluxDB::LineProtocol`:

    use InfluxDB::LineProtocol->import(qw(data2line precision=ms));

Please note that yo have to tell InfluxDB the precision when posting lines to `/write`!

# LOADING LEGACY PROTOCOL VERSIONS

To use an old version of the line protocol, specify the version you
want when loading `InfluxDB::LineProtocol`:

    use InfluxDB::LineProtocol qw(v0.9.2 data2line);

You will get a version of `data2line` that conforms to the `0.9.2`
version of the line protocol.

Currently supported version are:

- 0.9.3 and newer

    default, no need to specify anything

- 0.9.2

    load via `v0.9.2`

# TODO

- check if tag sorting algorithm matches
[http://golang.org/pkg/bytes/#Compare](http://golang.org/pkg/bytes/#Compare)

# SEE ALSO

- [InfluxDB](https://metacpan.org/pod/InfluxDB) provides access to the
old 0.8 API. It also allows searching etc.
- [AnyEvent::InfluxDB](https://metacpan.org/pod/AnyEvent::InfluxDB) - An
asynchronous library for InfluxDB time-series database. Does not
implement escaping etc, so if you want to use AnyEvent::InfluxDB to
send data to InfluxDB you can use InfluxDB::LineProtocol to convert
your measurement data structure before sending it via
AnyEvent::InfluxDB.

# THANKS

Thanks to

- [validad.com](http://www.validad.com/) for funding the
development of this code.
- [Jose Luis Martinez](https://github.com/pplu) for implementing
negative & exponential number support and pointing out the change in
the line protocol in 0.9.3.
- [mvgrimes](https://github.com/mvgrimes) for fixing a bug when
nanosecond timestamps cause some Perls to render the timestamp in
scientific notation.
- [Adrian Popa](https://github.com/mad-ady) for fixing a bug when
handling large scientific notation data.

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
