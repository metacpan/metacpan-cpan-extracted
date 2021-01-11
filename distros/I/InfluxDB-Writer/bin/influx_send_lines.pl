#!/usr/bin/env perl
use strict;
use warnings;
use lib::projectroot qw(lib local::lib=local);

# PODNAME: influx_send_lines.pl
# ABSTRACT: Manually send files to influxdb for non-live stats or replay
our $VERSION = '1.003'; # VERSION

package Runner;
use Moose;
extends 'InfluxDB::Writer::SendLines';
with 'MooseX::Getopt';

use Log::Any::Adapter ('Stderr');

my $runner = Runner->new_with_options->run;

__END__

=pod

=encoding UTF-8

=head1 NAME

influx_send_lines.pl - Manually send files to influxdb for non-live stats or replay

=head1 VERSION

version 1.003

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
