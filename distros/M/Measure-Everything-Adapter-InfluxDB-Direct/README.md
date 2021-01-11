# NAME

Measure::Everything::Adapter::InfluxDB::Direct - Send stats directly to InfluxDB via http

# VERSION

version 1.001

# SYNOPSIS

    Measure::Everything::Adapter->set( 'InfluxDB::Direct',
        host => 'influx.example.com',
        port => 8086,
        db   => 'conversions',
    );

    use Measure::Everything qw($stats);
    $stats->write('metric', 1);

# DESCRIPTION

Send stats directly to [InfluxDB](https://influxdb.com/). No buffering
whatsoever, so there is one HTTP request per call to
`$stats->write`. This might be a bad idea.

If a request fails, it will be logged using `Log::Any`, but no
further error handling is done. The metric will be lost.

### OPTIONS

Set these options when setting your adapter via `Measure::Everything::Adapter->set`

- host

    Required. Name of the host where your InfluxDB is running.

- db

    Required. Name of the database you want to use.

- port

    Optional. Defaults to 8086. Port your InfluxDB is listening on.

- username

    Optional. May be required by your InfluxDB.

- password

    Optional. May be required by your InfluxDB.

    `username` and `password` are sent in the `Authorization` header as `Basic` auth in `base64` encoding.

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
