# NAME

Measure::Everything - Log::Any for Stats

# VERSION

version 1.003

# SYNOPSIS

In a module where you want to count some stats:

    package Foo;
    use Measure::Everything qw($stats);

    $stats->write('jigawats', 1.21, { source=>'Plutonium', location=>'Hill Valley' });

In your application:

    use Foo;
    use Measure::Everything::Adapter;
    Measure::Everything::Adapter->set('InfluxDB::File', %args);

# DESCRIPTION

`Measure::Everything` tries to provide a standard measuring API for
modules (like [Log::Any](https://metacpan.org/pod/Log::Any) does for
logging). `Measure::Everything::Adapter`s allow applications to
choose the mechanism for measuring stats (for example
[InfluxDB](https://influxdb.com), [OpenTSDB](http://opentsdb.net/),
Graphite, etc).

For now, `Measure::Everything` only supports `InfluxDB`, because
that's what we're using. But I hope that other time series databases
(or other storage backends) can be added to `Measure::Everything`.
Unfortunately, measuring stats is not such a well-established domain
like logging (where we have a set of common log levels, and basically
"just" need to pass some string to some logging sink). So it is very
likely that `Measure::Everything` cannot provide a generic API, where
you can switch out Adapters without changing the measuring code. But
we can try!

`Measure::Everything` currently provides a way to access a global
object `$stats`, on which you can call the `write` method. The
currently active `Adapter` decides what to do with the data passed to
`write`. In contrast to `Log::Any`, there can be only one active
`Adapter`.

# PRODUCING STATS (FOR MODULES)

## Getting a stats handler

    use Measure::Everything qw($stats);

This will import a `$stats` object into your current namespace. What
this object will do depends on the active Adapter (see section
CONSUMING STATS)

## Counting

For now, `Measure::Everything` provides one method to write stats,
`write`:

    $stats->write($measurement, $value | \%values, \%tags?, $timestamp?);

It is still a bit uncertain whether this API will work for all
possible time series databases and other storage backends. But it
works for `InfluxDB`!

`$measurement` is the name of the thing you want to count.

`$value` or `\%values` is the value you want to count. Not all
databases can handle multiple values. In this case it should be the
job of the Adapter to convert the hashref of values into something the
storage backend can handle.

`\%tags` is a hashref of further tags. InfluxDB uses them, not sure
about other systems.

`$timestamp` is the time of the measurement. In general you should
not pass a timestamp and instead let the Adapter figure out the
current time and format it in a way the backend can understand. But if
you want to record stats for past (or future?) events, you will need
to pass in the timestamp in the correct format (or hope that the
Adapter will convert it for you).

# CONSUMING STATS (FOR APPLICATIONS)

`Application` here means the script running your modules. Could be a
daemon, a cron-job, a command line script, whatever. In this script
you will have to define what to do with stats generated in your
modules. You could throw them away (by using
`Measure::Everything::Adapter::Null`), which is the default. Or you
define an adapter, that will handle the data passed via `write`.

    use Measure::Everything::Adapter;
    Measure::Everything::Adapter->set('InfluxDB::File', file => '/tmp/my_app.stats');

# TODO

- tests
- docs
- Measure::Everything::Adapter::Memory
- Measure::Everything::Adapter::Test
- more InfluxDB Adapters: Direct, ZeroMQ, UDP, ..
- move Measure::Everything::Adapter::InfluxDB::\* into seperate distribution(s)

# SEE ALSO

The basic concept is stolen from
<Log::Any|https://metacpan.org/pod/Log::Any>. If you have troubles
understanding this set of modules, please read the excellent Log::Any
docs, and substitue "logging" with "writing stats".

For more information on measuring & stats, and the obvious inspiration
for this module's name, read the interesting article [Measure
    Anything, Measure
    Everything](https://codeascraft.com/2011/02/15/measure-anything-measure-everything/)
    by Ian Malpass from [Etsy](http://etsy.com/).

# THANKS

Thanks to

- [validad.com](http://www.validad.com/) for funding the
development of this code.

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
