#!/usr/bin/env perl
use v5.36;
use Getopt::Long qw(GetOptions);
use Time::HiRes qw(clock_gettime CLOCK_PROCESS_CPUTIME_ID);
use JSON::PP;
use Unblock::HTTP::Server;
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::_Wire;

# No sockets and no Linux::Event code. This isolates the engine/response
# cost; it is diagnostic, not an alternative end-to-end throughput claim.
package BenchSink;
sub new { bless { bytes => 0 }, shift }
sub unblock_send ($self, $bytes) { $self->{bytes} += length($bytes); return 1 }
sub unblock_finish { }
sub unblock_abort { die $_[1] }
package main;
my $requests = 100_000;
my ($json, $case_name);
my $nytprof = 0;
my $native_input = 0;
GetOptions('requests=i' => \$requests, 'json=s' => \$json,
    'case=s' => \$case_name, 'nytprof!' => \$nytprof,
    'native-input!' => \$native_input) or die 'bad options';
die 'unknown --case' if defined($case_name) && $case_name !~ /\A(?:engine_input_and_response|response_construction|response_construction_and_wire_plan)\z/;
die '--nytprof requires --case, -d:NYTProf and NYTPROF=start=no'
    if $nytprof && (!defined($case_name) || !defined(&DB::enable_profile)
        || ($ENV{NYTPROF} // '') !~ /(?:\A|:)start=no(?:\z|:)/);
die 'requests must be positive' unless $requests > 0;
my $body = 'x' x 32;
my $wire = "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n";
my $sink = BenchSink->new;
my $definition = Unblock::HTTP::Server->new(http1 => {},
    on_request => sub ($tx, $request) { $tx->respond(status => 200, body => $body) });
my $engine = $definition->attach_stream(transport => $sink);
my $request = Uniform::HTTP::Request->new(method => 'GET', target => '/', version => '1.1');
# Use the released engine's own diagnostic driver, not a Linux transport.
# This private helper is benchmark-only and is never part of the adapter API.
my $driver = $native_input
    ? Unblock::HTTP1::_Native::BorrowedDriver->new($engine) : undef;
my $engine_run = $native_input ? sub {
    my ($status, $used) = $driver->feed($wire);
    die 'incomplete native benchmark input' unless $status == 0 && $used == length($wire);
} : sub { $engine->input($wire) };
my @rows;
for my $case (
    ['engine_input_and_response', $engine_run],
    ['response_construction', sub { Uniform::HTTP::Response->new(status => 200, body => $body) }],
    ['response_construction_and_wire_plan', sub {
        Unblock::HTTP1::_Wire::response_plan($request,
            Uniform::HTTP::Response->new(status => 200, body => $body));
    }],
) {
    my ($name, $run) = @$case;
    next if defined($case_name) && $name ne $case_name;
    DB::enable_profile() if $nytprof;
    $run->() for 1 .. 1000;
    my $start = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
    $run->() for 1 .. $requests;
    my $cpu = clock_gettime(CLOCK_PROCESS_CPUTIME_ID) - $start;
    DB::finish_profile() if $nytprof;
    push @rows, { name => $name, native_input => $native_input,
        iterations => $requests, cpu_seconds => $cpu,
        cpu_us_per_iteration => $cpu * 1_000_000 / $requests };
    printf "%s %.3f CPU us/iteration\n", $name, $cpu * 1_000_000 / $requests;
}
if ($json) {
    open my $fh, '>', $json or die "$json: $!";
    print {$fh} JSON::PP->new->canonical->pretty->encode(\@rows);
    close $fh or die $!;
}
