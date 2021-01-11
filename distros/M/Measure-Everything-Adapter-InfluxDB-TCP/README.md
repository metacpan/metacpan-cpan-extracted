# NAME

Measure::Everything::Adapter::InfluxDB::TCP - Send stats to Influx via TCP using Telegraf

# VERSION

version 1.004

# SYNOPSIS

    Measure::Everything::Adapter->set( 'InfluxDB::TCP',
        host => 'localhost',   # default
        port => 8094,          # default
        precision => 'ms'      # default is ns (nanoseconds)
    );

    use Measure::Everything qw($stats);
    $stats->write('metric', 1);

# DESCRIPTION

Send stats via TCP to a
[Telegraf](https://influxdata.com/time-series-platform/telegraf/)
service, which will forward them to [InfluxDB](https://influxdb.com/).
No buffering whatsoever, so there is one TCP request per call to
`$stats->write`. This might be a bad idea.

If TCP listener is not available when `set` is called, an error will
be written via `Log::Any`. `write` will silently discard all
metrics, no data will be sent to Telegraf / InfluxDB.

If a request fails no further error handling is done. The metric will
be lost.

### OPTIONS

Set these options when setting your adapter via `Measure::Everything::Adapter->set`

- host

    Name of the host where your Telegraf is running. Default to `localhost`.

- port

    Port your Telegraf is listening. Defaults to `8094`.

- precision

    A valid InfluxDB precision. Default to undef (i.e. nanoseconds). Do
    not set it if you're talking with Telegraf, as Telegraf will always
    interpret the timestamp as nanoseconds.

### Handling server disconnect

`Measure::Everything::Adapter::InfluxDB::TCP` installs a `local`
handler for `SIGPIPE` to handle a disconnect from the server. If the
server goes away, `InfluxDB::TCP` will try to reconnect every time a
stat is written. As of now (1.003), this behavior is hardcoded.

You might want to check out
[Measure::Everything::Adapter::InfluxDB::UDP](https://metacpan.org/pod/Measure%3A%3AEverything%3A%3AAdapter%3A%3AInfluxDB%3A%3AUDP) for an even lossier,
but more failure tolerant way to send your stats.

See also [this blog post](http://domm.plix.at/perl/2016_09_too_dumb_for_tcp.html), where
HJansen provided the correct solution to my problem. Nicholas Clark
also pointed me in the right direction (in #Austria.pm)

### Example

See ["send\_metrics.pl" in example](https://metacpan.org/pod/example#send_metrics.pl) for a working example.

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
