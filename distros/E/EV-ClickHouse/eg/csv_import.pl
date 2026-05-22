#!/usr/bin/env perl
# CSV → ClickHouse using insert_iter with auto-discovered columns.
#
# The schema is taken from the target table via columns_from_table so
# this script is schema-agnostic: as long as the CSV header matches the
# table's column names, no manual mapping is needed.
#
# Backpressure is automatic — insert_iter pauses the producer when the
# streamer's buffer hits the high-water mark.
#
# Usage:
#   clickhouse-client -q "create table events (ts DateTime, user_id UInt64, action String) engine=Memory"
#   ./eg/csv_import.pl events < events.csv
#
# CSV format: first line is header (comma-separated column names matching
# the table), subsequent lines are values. No quoting / escaping support —
# this is a starter, not a full RFC 4180 parser. For production use
# Text::CSV_XS instead.

use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $table = shift @ARGV or die "Usage: $0 <table> < input.csv\n";
my $batch = $ENV{BATCH_SIZE} // 10_000;

# Read the header so we can route by column name.
my $header = <STDIN>;
chomp $header;
my @csv_cols = split /,/, $header;

my $ch; $ch = EV::ClickHouse->new(
    host     => $ENV{CLICKHOUSE_HOST}        // '127.0.0.1',
    port     => $ENV{CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol => 'native',
    on_connect => sub {
        my $rows = 0;
        my $start = EV::time;
        my $streamer = $ch->insert_streamer($table, batch_size => $batch);

        $streamer->columns_from_table(sub {
            my ($err) = @_;
            die "describe $table: $err" if $err;

            # Verify CSV header matches the table's columns (order
            # doesn't matter — push_row in named-rows mode reorders).
            my %want = map { $_ => 1 } @{ $streamer->{columns} };
            my @bad  = grep { !$want{$_} } @csv_cols;
            die "CSV columns not in table: @bad" if @bad;

            $ch->insert_iter($table, sub {
                my $line = <STDIN>;
                return undef unless defined $line;
                chomp $line;
                $rows++;
                my @fields = split /,/, $line, -1;
                +{ map { ($csv_cols[$_], $fields[$_]) } 0 .. $#csv_cols };
            }, sub {
                my (undef, $err) = @_;
                die "insert: $err" if $err;
                printf STDERR "imported %d rows in %.2fs (%.0f rows/s)\n",
                    $rows, EV::time - $start, $rows / (EV::time - $start || 1);
                EV::break;
            }, batch_size => $batch, columns => $streamer->{columns});
        });
    },
    on_error => sub { die "ch: $_[0]\n" },
);

EV::run;
$ch->finish;
