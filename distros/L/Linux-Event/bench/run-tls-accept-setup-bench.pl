#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use Getopt::Long qw(GetOptions);
use JSON::PP qw(encode_json);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC CLOCK_PROCESS_CPUTIME_ID);

use Linux::Event::IO::Sock::Stream;
use Linux::Event::TLS;

{
    package Linux::Event::TLS::Bench::ServerStream;
    use parent 'Linux::Event::IO::Sock::Stream';

    sub tls_defaults ($class) {
        return alpn => ['tls-setup-bench/1'];
    }

    sub on_data ($stream, $bytes) { return }
}

my $iterations = 1_000;
my $repeats = 7;
my $json_file;
my $cert_file = "$Bin/../t/tls-certs/server-cert.pem";
my $key_file = "$Bin/../t/tls-certs/server-key.pem";

GetOptions(
    'iterations=i' => \$iterations,
    'repeats=i'    => \$repeats,
    'json=s'       => \$json_file,
    'cert-file=s'  => \$cert_file,
    'key-file=s'   => \$key_file,
) or die "bad options\n";

die "iterations must be > 0\n" if $iterations <= 0;
die "repeats must be > 0\n" if $repeats <= 0;
die "TLS certificate file not found: $cert_file\n" if !-f $cert_file;
die "TLS private-key file not found: $key_file\n" if !-f $key_file;

my $template_wall_start = clock_gettime(CLOCK_MONOTONIC);
my $template_cpu_start = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
my $template = Linux::Event::TLS->_prepare_listener_server(
    'Linux::Event::TLS::Bench::ServerStream',
    {
        cert_file => $cert_file,
        key_file  => $key_file,
    },
);
my $template_cpu = clock_gettime(CLOCK_PROCESS_CPUTIME_ID) - $template_cpu_start;
my $template_wall = clock_gettime(CLOCK_MONOTONIC) - $template_wall_start;

my @systems = qw(fresh_context prepared_clone);
my @rows;

say 'TLS accepted-connection setup benchmark';
say "iterations=$iterations repeats=$repeats";
printf "prepared server context once: %.3f ms wall %.3f ms cpu\n",
    $template_wall * 1_000, $template_cpu * 1_000;

for my $repeat (1 .. $repeats) {
    my @order = $repeat % 2 ? @systems : reverse @systems;
    for my $system (@order) {
        my $wall_start = clock_gettime(CLOCK_MONOTONIC);
        my $cpu_start = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);

        if ($system eq 'fresh_context') {
            for (1 .. $iterations) {
                my $transport = Linux::Event::TLS->server(
                    cert_file => $cert_file,
                    key_file  => $key_file,
                    alpn      => ['tls-setup-bench/1'],
                );
                undef $transport;
            }
        } else {
            for (1 .. $iterations) {
                my $transport = Linux::Event::TLS->_listener_server_connection(
                    $template,
                );
                undef $transport;
            }
        }

        my $cpu = clock_gettime(CLOCK_PROCESS_CPUTIME_ID) - $cpu_start;
        my $wall = clock_gettime(CLOCK_MONOTONIC) - $wall_start;
        my $row = {
            system                => $system,
            repeat                => $repeat,
            iterations            => $iterations,
            wall_seconds          => $wall,
            cpu_seconds           => $cpu,
            setups_per_second     => $iterations / $wall,
            wall_us_per_setup     => $wall * 1_000_000 / $iterations,
            cpu_us_per_setup      => $cpu * 1_000_000 / $iterations,
        };
        push @rows, $row;
        printf "%s repeat=%d %.1f setup/s wall=%.3f us/setup cpu=%.3f us/setup\n",
            $system, $repeat, $row->{setups_per_second},
            $row->{wall_us_per_setup}, $row->{cpu_us_per_setup};
    }
}

say "\nMedian TLS setup summary";
printf "%-15s %14s %16s %16s\n",
    'system', 'setup/s', 'wall us/setup', 'cpu us/setup';
for my $system (@systems) {
    my @set = grep { $_->{system} eq $system } @rows;
    printf "%-15s %14.1f %16.3f %16.3f\n",
        $system,
        median(map { $_->{setups_per_second} } @set),
        median(map { $_->{wall_us_per_setup} } @set),
        median(map { $_->{cpu_us_per_setup} } @set);
}

if (defined $json_file) {
    open my $json_fh, '>', $json_file
        or die "open $json_file: $!\n";
    print {$json_fh} encode_json({
        benchmark => 'linux-event-tls-accepted-connection-setup',
        iterations => $iterations,
        repeats => $repeats,
        prepared_context_wall_seconds => $template_wall,
        prepared_context_cpu_seconds => $template_cpu,
        rows => \@rows,
    });
    print {$json_fh} "\n";
    close $json_fh or die "close $json_file: $!\n";
}

say "\nfresh_context constructs and loads a server SSL_CTX for every connection.";
say "prepared_clone reuses one Listener-style prepared SSL_CTX and allocates";
say "only independent per-connection TLS state. No handshake is timed.";

sub median (@values) {
    @values = sort { $a <=> $b } @values;
    return $values[int(@values / 2)] if @values % 2;
    return ($values[@values / 2 - 1] + $values[@values / 2]) / 2;
}
