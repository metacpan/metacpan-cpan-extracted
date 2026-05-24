#!/usr/bin/env perl
# High-Performance HTTP Benchmark using wrk
#
# Uses wrk (https://github.com/wg/wrk) for accurate, high-throughput benchmarking.
# This eliminates Perl client overhead and shows true server performance.

use strict;
use warnings;
use lib 'lib';
use lib '../XS-JIT/blib/lib';
use lib '../XS-JIT/blib/arch';

use Time::HiRes qw(time sleep);
use IO::Socket::INET;
use POSIX ":sys_wait_h";

# Check for wrk
my $wrk = `which wrk 2>/dev/null`;
chomp $wrk;
die "wrk not found. Install with: brew install wrk\n" unless $wrk;

my $DURATION = $ARGV[0] // 10;  # seconds
my $THREADS = $ARGV[1] // 2;
my $CONNECTIONS = $ARGV[2] // 100;
my $PORT_BASE = 30000 + ($$ % 1000);

print "=" x 70, "\n";
print "High-Performance HTTP Benchmark (wrk)\n";
print "=" x 70, "\n\n";
print "Duration: ${DURATION}s, Threads: $THREADS, Connections: $CONNECTIONS\n\n";

# ============================================================================
# Framework detection
# ============================================================================

my %available = (Hypersonic => 1);

eval { require Mojolicious; $available{Mojolicious} = $Mojolicious::VERSION; };
eval { require Dancer2; $available{Dancer2} = $Dancer2::VERSION; };

print "Available frameworks:\n";
for my $fw (sort keys %available) {
    print "  - $fw" . ($available{$fw} ne '1' ? " v$available{$fw}" : "") . "\n";
}
print "\n";

my @pids;
my @results;

# ============================================================================
# Benchmark helper using wrk
# ============================================================================

sub wait_for_server {
    my ($port) = @_;
    for (1..50) {
        my $sock = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Proto    => 'tcp',
            Timeout  => 0.1,
        );
        if ($sock) {
            close($sock);
            return 1;
        }
        sleep(0.1);
    }
    return 0;
}

sub benchmark_with_wrk {
    my ($name, $port) = @_;
    
    print "Benchmarking $name on port $port...\n";
    
    unless (wait_for_server($port)) {
        print "  SKIP: Server not responding\n\n";
        return undef;
    }
    
    # Run wrk
    my $url = "http://127.0.0.1:$port/hello";
    my $cmd = "$wrk -t$THREADS -c$CONNECTIONS -d${DURATION}s $url 2>&1";
    my $output = `$cmd`;
    
    # Parse wrk output
    my ($rps) = $output =~ /Requests\/sec:\s+([\d.]+)/;
    my ($latency) = $output =~ /Latency\s+([\d.]+)(\w+)/;
    my $latency_unit = $2 // 'ms';
    
    # Convert to ms
    if ($latency_unit eq 'us') {
        $latency /= 1000;
    } elsif ($latency_unit eq 's') {
        $latency *= 1000;
    }
    
    my ($transfer) = $output =~ /Transfer\/sec:\s+([\d.]+\w+)/;
    
    printf "  Requests/sec: %s\n", $rps // 'N/A';
    printf "  Latency:      %.2f ms\n", $latency // 0;
    printf "  Transfer:     %s\n", $transfer // 'N/A';
    print "\n";
    
    return { name => $name, rps => $rps // 0, latency => $latency // 0 };
}

# ============================================================================
# Start Hypersonic server
# ============================================================================

my $hs_port = $PORT_BASE;
my $hs_pid = fork();
die "Fork failed" unless defined $hs_pid;

if ($hs_pid == 0) {
    require Hypersonic;
    my $server = Hypersonic->new(cache_dir => "_bench_wrk_$$");
    $server->get('/hello' => sub { 'Hello, World!' }, { dynamic => 1 });
    $server->compile();
    $server->run(port => $hs_port, workers => 1);
    exit(0);
}
push @pids, $hs_pid;

sleep(2);  # Let server compile and start

my $hs_result = benchmark_with_wrk("Hypersonic", $hs_port);
push @results, $hs_result if $hs_result;

# ============================================================================
# Start Mojolicious server (if available)
# ============================================================================

if ($available{Mojolicious}) {
    my $mojo_port = $PORT_BASE + 1;
    my $mojo_pid = fork();
    die "Fork failed" unless defined $mojo_pid;
    
    if ($mojo_pid == 0) {
        eval q{
            use Mojolicious::Lite -signatures;
            app->log->level('fatal');
            get '/hello' => sub ($c) { $c->render(text => 'Hello, World!') };
            app->start('daemon', '-l', "http://127.0.0.1:$mojo_port", '-m', 'production');
        };
        exit(0);
    }
    push @pids, $mojo_pid;
    
    sleep(2);
    
    my $mojo_result = benchmark_with_wrk("Mojolicious", $mojo_port);
    push @results, $mojo_result if $mojo_result;
}

# ============================================================================
# Start Dancer2 server (if available)
# ============================================================================

if ($available{Dancer2}) {
    my $dancer_port = $PORT_BASE + 2;
    my $dancer_pid = fork();
    die "Fork failed" unless defined $dancer_pid;
    
    if ($dancer_pid == 0) {
        eval q{
            package BenchDancer;
            use Dancer2;
            set logger => 'Null';
            set show_errors => 0;
            get '/hello' => sub { 'Hello, World!' };
            
            require Plack::Runner;
            my $runner = Plack::Runner->new;
            $runner->parse_options(
                '--port' => $dancer_port,
                '--server' => 'HTTP::Server::PSGI',
                '--env' => 'production',
            );
            $runner->run(BenchDancer->to_app);
        };
        exit(0);
    }
    push @pids, $dancer_pid;
    
    sleep(2);
    
    my $dancer_result = benchmark_with_wrk("Dancer2", $dancer_port);
    push @results, $dancer_result if $dancer_result;
}

# ============================================================================
# Cleanup and Summary
# ============================================================================

print "Shutting down servers...\n";
for my $pid (@pids) {
    kill('TERM', $pid);
    waitpid($pid, 0);
}

system("rm -rf _bench_wrk_*");

print "\n";
print "=" x 70, "\n";
print "SUMMARY - Requests/sec (higher is better)\n";
print "=" x 70, "\n\n";

@results = sort { $b->{rps} <=> $a->{rps} } @results;

if (@results) {
    my $baseline = $results[0]->{rps};
    
    printf "%-20s %15s %12s %10s\n", "Framework", "Req/sec", "Latency(ms)", "Relative";
    print "-" x 60, "\n";
    
    for my $r (@results) {
        my $relative = $r->{rps} / $baseline;
        printf "%-20s %15.0f %12.2f %9.1fx\n", 
               $r->{name}, $r->{rps}, $r->{latency}, $relative;
    }
}

print "\n";
print "Note: wrk uses connection pooling (keep-alive) for maximum throughput.\n";
print "Run with: perl bench/wrk.pl [duration] [threads] [connections]\n";
