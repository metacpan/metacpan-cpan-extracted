# NAME

Log::Log4perl::Layout::JSON::Readable - JSON layout, but some fields always come first
# DESCRIPTION

This layout works just like [`Log::Log4perl::Layout::JSON`](https://metacpan.org/pod/Log::Log4perl::Layout::JSON), but
it always prints some fields first, even with `canonical => 1`.

The fields to print first are set via the `first_fields` attribute,
which is a comma-separated list of field names (defaults to `time,
pid, level`, like in the synopsis).

So, instead of:

    {"category":"App.Minion.stats","level":"TRACE","message":"Getting metrics","pid":"6689","time":"2018-04-04 13:57:23,990"}

you get:

    {"time":"2018-04-04 13:57:23,990","pid":"6689","level":"TRACE","category":"App.Minion.stats","message":"Getting metrics"}

which is more readable (e.g. for the timestamp) and usable (e.g. for
the pid).

# AUTHORS

- Johan Lindstrom <Johan.Lindstrom@broadbean.com>
- Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
