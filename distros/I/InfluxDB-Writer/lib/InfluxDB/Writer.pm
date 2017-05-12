package InfluxDB::Writer;
use strict;
use warnings;

our $VERSION = '1.002';

# ABSTRACT: Various tools to send lines to InfluxDB

__END__

=pod

=encoding UTF-8

=head1 NAME

InfluxDB::Writer - Various tools to send lines to InfluxDB

=head1 VERSION

version 1.002

=head1 DESCRIPTION

C<InfluxDB::Writer> is a collection of tools & modules to send L<lines|https://influxdb.com/docs/v0.9/write_protocols/line.html> to L<InfluxDB|https://influxdb.com>

Currently, the suggested setup is to have your apps write stats into a file containing the PID of the process. This file (or files) can then be processed by various tools provided by C<InfluxDB::Writer> and their contents sent to InfluxDB.

=over

=item L<InfluxDB::Writer::FileTailer>

A daemon using C<IO::Async> to watch a directory. All files in this directory that include the PID of a currently running process are tailed and any new lines added sent to InfluxDB in batches. New files added to the directory are also automatically tailed.

=item L<InfluxDB::Writer::SendLines>

A script that takes one file and send the lines to InfluxDB in batches.

=item L<InfluxDB::Writer::CompactFiles>

A script that checks all files in a directory. All files that contain PIDs of not longer running processes are compacted into one file which is then C<gzip>ed.

=back

Please refer to the documentation of the respective modules for detailed information.

=head1 EXAMPLE USAGE

We use L<Measure::Everything::InfluxDB::

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
