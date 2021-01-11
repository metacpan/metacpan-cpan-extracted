# NAME

InfluxDB::Writer - Various tools to send lines to InfluxDB

# VERSION

version 1.003

# DESCRIPTION

`InfluxDB::Writer` is a collection of tools & modules to send [lines](https://influxdb.com/docs/v0.9/write_protocols/line.html) to [InfluxDB](https://influxdb.com)

Currently, the suggested setup is to have your apps write stats into a file containing the PID of the process. This file (or files) can then be processed by various tools provided by `InfluxDB::Writer` and their contents sent to InfluxDB.

- [InfluxDB::Writer::FileTailer](https://metacpan.org/pod/InfluxDB%3A%3AWriter%3A%3AFileTailer)

    A daemon using `IO::Async` to watch a directory. All files in this directory that include the PID of a currently running process are tailed and any new lines added sent to InfluxDB in batches. New files added to the directory are also automatically tailed.

- [InfluxDB::Writer::SendLines](https://metacpan.org/pod/InfluxDB%3A%3AWriter%3A%3ASendLines)

    A script that takes one file and send the lines to InfluxDB in batches.

- [InfluxDB::Writer::CompactFiles](https://metacpan.org/pod/InfluxDB%3A%3AWriter%3A%3ACompactFiles)

    A script that checks all files in a directory. All files that contain PIDs of not longer running processes are compacted into one file which is then `gzip`ed.

Please refer to the documentation of the respective modules for detailed information.

# EXAMPLE USAGE

We use [Measure::Everything::InfluxDB::](https://metacpan.org/pod/Measure%3A%3AEverything%3A%3AInfluxDB%3A%3A)

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 39:

    Unterminated L<...> sequence
