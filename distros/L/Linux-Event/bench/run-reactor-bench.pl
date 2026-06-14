#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch", "$FindBin::Bin/lib", "$FindBin::Bin/../lib";
use Getopt::Long qw(GetOptionsFromArray);
use File::Path qw(make_path);
use JSON::PP ();
use Linux::Event::Bench;

my $RESULT_DIR = 'bench/results';

my @SUITE = (
  {
    name     => 'echo_tcp',
    file     => 'echo',
    multi    => 1,
    defaults => {
      clients      => '1,10,50,100',
      messages     => 1000,
      message_size => 64,
    },
  },
  {
    name     => 'pipe_churn',
    file     => 'pipe',
    defaults => {
      events => 1_000_000,
    },
  },
  {
    name     => 'watcher_churn',
    file     => 'watchers',
    defaults => {
      events => 100_000,
    },
  },
  {
    name     => 'callback_storm',
    file     => 'callbacks',
    defaults => {
      events => 1_000_000,
      fds    => 1000,
    },
  },
  {
    name     => 'timer_heap',
    file     => 'timers',
    defaults => {
      events => 50_000,
    },
  },
);

my @args = @ARGV;
my $cmd = shift(@args) // '';

if ($cmd eq '' || $cmd eq 'help' || $cmd eq '--help' || $cmd eq '-h') {
  print usage();
  exit 0;
}

if ($cmd eq 'compare') {
  my ($before_phase, $after_phase) = @args;
  die usage() if !defined($before_phase) || !defined($after_phase);
  compare_phases($before_phase, $after_phase);
  exit 0;
}

if ($cmd =~ /^phase\d+[A-Za-z0-9_\-]*$/) {
  run_phase($cmd, \@args);
  exit 0;
}

# Backward-compatible expert mode for one-off scenario runs.
unshift @args, $cmd;
run_single(\@args);
exit 0;

sub run_phase ($phase, $argv) {
  my %opt = (
    backend => $phase eq 'phase0' ? 'pp' : 'xs',
    dir     => $RESULT_DIR,
  );

  GetOptionsFromArray(
    $argv,
    'backend=s' => \$opt{backend},
    'dir=s'     => \$opt{dir},
    'help'      => \my $help,
  ) or die usage();

  if ($help) {
    print usage();
    return;
  }

  make_path($opt{dir}) if !-d $opt{dir};

  print "Running Linux::Event reactor benchmark suite\n";
  print "  phase:   $phase\n";
  print "  backend: $opt{backend}\n";
  print "  results: $opt{dir}\n\n";

  for my $bench (@SUITE) {
    my $path = "$opt{dir}/$phase-$bench->{file}.json";
    unlink $path if -e $path;

    my %args = (
      backend => $opt{backend},
      phase   => $phase,
      %{ $bench->{defaults} },
    );

    print "== $bench->{name} -> $path ==\n";

    if ($bench->{multi}) {
      my @client_counts = split /,/, $args{clients};
      my @results;
      for my $c (@client_counts) {
        my $res = Linux::Event::Bench::run_scenario($bench->{name}, {
          %args,
          clients => int($c),
        });
        push @results, $res;
        print_result($res);
      }
      Linux::Event::Bench::write_json($path, {
        phase    => $phase,
        backend  => $opt{backend},
        scenario => $bench->{name},
        results  => \@results,
      });
    }
    else {
      my $res = Linux::Event::Bench::run_scenario($bench->{name}, \%args);
      print_result($res);
      Linux::Event::Bench::write_json($path, $res);
    }

    print "\n";
  }
}

sub run_single ($argv) {
  my $backend = 'pp';
  my $phase = 'manual';
  my $scenario = 'echo_tcp';
  my $clients = '1';
  my $messages = 1000;
  my $message_size = 64;
  my $events;
  my $fds;
  my $json;
  my $help;

  GetOptionsFromArray(
    $argv,
    'backend=s'      => \$backend,
    'phase=s'        => \$phase,
    'scenario=s'     => \$scenario,
    'clients=s'      => \$clients,
    'messages=i'     => \$messages,
    'message-size=i' => \$message_size,
    'events=i'       => \$events,
    'fds=i'          => \$fds,
    'json=s'         => \$json,
    'help'           => \$help,
  ) or die usage();

  if ($help) {
    print usage();
    return;
  }

  my @client_counts = split /,/, $clients;
  my @results;
  for my $c (@client_counts) {
    my $res = Linux::Event::Bench::run_scenario($scenario, {
      backend      => $backend,
      phase        => $phase,
      clients      => int($c),
      messages     => $messages,
      message_size => $message_size,
      defined($events) ? (events => $events) : (),
      defined($fds)    ? (fds    => $fds)    : (),
    });
    push @results, $res;
    print_result($res);
  }

  my $out = @results == 1 ? $results[0] : {
    phase    => $phase,
    backend  => $backend,
    scenario => $scenario,
    results  => \@results,
  };
  Linux::Event::Bench::write_json($json, $out) if defined $json;
}

sub compare_phases ($before_phase, $after_phase) {
  print "Comparing $before_phase -> $after_phase\n\n";

  for my $bench (@SUITE) {
    my $before_path = "$RESULT_DIR/$before_phase-$bench->{file}.json";
    my $after_path  = "$RESULT_DIR/$after_phase-$bench->{file}.json";

    if (!-e $before_path || !-e $after_path) {
      warn "Skipping $bench->{name}: missing $before_path or $after_path\n";
      next;
    }

    my $before = Linux::Event::Bench::read_json($before_path);
    my $after  = Linux::Event::Bench::read_json($after_path);

    print "== $bench->{name} ==\n";
    if ($bench->{multi}) {
      my $b_results = $before->{results} // [];
      my $a_results = $after->{results} // [];
      my %after_by_clients = map { ($_->{clients} // '') => $_ } @$a_results;
      for my $b (@$b_results) {
        my $clients = $b->{clients} // '';
        my $a = $after_by_clients{$clients};
        next if !$a;
        print "clients=$clients\n";
        print_compare_rows(Linux::Event::Bench::compare_results($b, $a));
      }
    }
    else {
      print_compare_rows(Linux::Event::Bench::compare_results($before, $after));
    }
    print "\n";
  }
}

sub print_compare_rows ($rows) {
  printf "%-24s %16s %16s %16s %12s\n", qw(metric before after delta percent);
  for my $r (@$rows) {
    printf "%-24s %16s %16s %16.4f %12s\n", @$r;
  }
}

sub print_result ($r) {
  my $rate = $r->{messages_per_second}
          // $r->{events_per_second}
          // $r->{callbacks_per_second}
          // $r->{watchers_per_second}
          // $r->{timers_per_second};
  printf "%s backend=%s phase=%s elapsed=%.6fs rate=%s/s\n",
    $r->{scenario}, $r->{backend}, $r->{phase}, $r->{elapsed_seconds}, defined($rate) ? $rate : 'n/a';
  if (exists $r->{p50_latency_us}) {
    printf "  latency_us p50=%s p95=%s p99=%s\n",
      ($r->{p50_latency_us} // 'n/a'), ($r->{p95_latency_us} // 'n/a'), ($r->{p99_latency_us} // 'n/a');
  }
}

sub usage () {
  return <<'USAGE';
Usage:
  perl bench/run-reactor-bench.pl phase0 [--backend pp|xs]
  perl bench/run-reactor-bench.pl phase012 [--backend pp|xs]
  perl bench/run-reactor-bench.pl compare phase0 phase012

Normal workflow:
  perl bench/run-reactor-bench.pl phase0 --backend pp
  perl bench/run-reactor-bench.pl phase012 --backend xs
  perl bench/run-reactor-bench.pl compare phase0 phase012

Phase mode:
  Any label matching phaseN or phaseNsuffix runs the standard benchmark suite
  and writes these files:
    bench/results/<phase>-echo.json
    bench/results/<phase>-pipe.json
    bench/results/<phase>-watchers.json
    bench/results/<phase>-callbacks.json
    bench/results/<phase>-timers.json

  Existing files for the same phase are overwritten.

Defaults:
  phase0 uses --backend pp
  any other phase label uses --backend xs

Options for phase mode:
  --backend pp|xs    Override backend label
  --dir PATH         Override result directory. Default: bench/results

Expert one-off mode is still available:
  perl bench/run-reactor-bench.pl --scenario echo_tcp --clients 1,10,50,100 --json bench/results/manual-echo.json
  perl bench/run-reactor-bench.pl --scenario callback_storm --events 1000000 --fds 1000 --json bench/results/manual-callbacks.json
USAGE
}
