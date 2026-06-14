package Linux::Event::Bench;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.012';

use Carp qw(croak);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use IO::Socket::INET;
use POSIX qw(:sys_wait_h);
use Socket qw(SOL_SOCKET SO_REUSEADDR IPPROTO_TCP TCP_NODELAY);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC sleep);
use JSON::PP qw(encode_json decode_json);

sub monotonic () { return clock_gettime(CLOCK_MONOTONIC) }

sub percentile ($vals, $p) {
  return undef if !$vals || !@$vals;
  my @s = sort { $a <=> $b } @$vals;
  my $idx = int(((@s - 1) * $p) + 0.5);
  $idx = 0 if $idx < 0;
  $idx = $#s if $idx > $#s;
  return $s[$idx];
}

sub max_rss_kb () {
  if (open my $fh, '<', '/proc/self/status') {
    while (my $line = <$fh>) {
      return int($1) if $line =~ /^VmHWM:\s+(\d+)\s+kB/;
    }
  }
  return undef;
}

sub slurp ($path) {
  open my $fh, '<', $path or croak "open $path: $!";
  local $/;
  return <$fh>;
}

sub write_json ($path, $data) {
  open my $fh, '>', $path or croak "write $path: $!";
  print {$fh} JSON::PP->new->canonical->pretty->encode($data);
  close $fh or croak "close $path: $!";
}

sub read_json ($path) {
  return decode_json(slurp($path));
}

sub git_commit () {
  my $git = `git rev-parse --short HEAD 2>/dev/null`;
  chomp $git;
  return length($git) ? $git : undef;
}

sub kernel_version () {
  my $u = `uname -r 2>/dev/null`;
  chomp $u;
  return length($u) ? $u : undef;
}

sub make_backend ($name) {
  $name //= 'pp';
  if ($name eq 'pp' || $name eq 'epoll') {
    require Linux::Event::Backend::Epoll;
    return Linux::Event::Backend::Epoll->new;
  }
  if ($name eq 'xs') {
    # The public backend class name stays Linux::Event::Backend::Epoll.
    # XS hot paths are loaded inside that backend, so the benchmark label can
    # be 'xs' without requiring a separate public Epoll::XS package.
    require Linux::Event::Backend::Epoll;
    return Linux::Event::Backend::Epoll->new;
  }
  croak "unknown backend '$name'";
}

sub make_loop ($backend_name) {
  require Linux::Event;
  return Linux::Event->new(backend => make_backend($backend_name));
}

sub set_nonblocking ($fh) {
  my $flags = fcntl($fh, F_GETFL, 0);
  croak "fcntl(F_GETFL): $!" if !defined $flags;
  croak "fcntl(F_SETFL): $!" if !fcntl($fh, F_SETFL, $flags | O_NONBLOCK);
  return 1;
}

sub _base_result ($args, $start, $end, $cpu0, $cpu1) {
  my $elapsed = $end - $start;
  $elapsed = 0.000001 if $elapsed <= 0;
  return {
    backend          => $args->{backend},
    phase            => $args->{phase},
    scenario         => $args->{scenario},
    elapsed_seconds  => 0 + sprintf('%.6f', $elapsed),
    user_cpu_seconds => 0 + sprintf('%.6f', $cpu1->[0] - $cpu0->[0]),
    system_cpu_seconds => 0 + sprintf('%.6f', $cpu1->[1] - $cpu0->[1]),
    max_rss_kb       => max_rss_kb(),
    perl_version     => "$^V",
    linux_kernel     => kernel_version(),
    git_commit       => git_commit(),
  };
}

sub run_pipe_churn ($args) {
  # Real pipe readiness benchmark.
  #
  # One callback equals one event.  The watcher reads exactly one byte and then
  # writes one byte back into the pipe to re-arm readability.  This avoids the
  # previous bulk-byte benchmark, which could process millions of bytes in a few
  # syscalls and report an unrealistically high "events/sec" rate.
  my $events = int($args->{events} // $args->{messages} // 1_000_000);
  croak "events must be positive" if $events <= 0;

  pipe(my $r, my $w) or croak "pipe: $!";
  set_nonblocking($r);
  set_nonblocking($w);

  my $loop = make_loop($args->{backend});
  my $seen = 0;
  my $buf = '';

  $loop->watch($r, read => sub ($loop, $fh, $watcher) {
    my $n = sysread($fh, $buf, 1);
    die "pipe_churn sysread: $!" if !defined($n) && !$!{EAGAIN};
    return if !defined($n) || $n == 0;

    ++$seen;
    if ($seen >= $events) {
      $loop->stop;
      return;
    }

    my $wn = syswrite($w, 'x');
    die "pipe_churn syswrite: $!" if !defined($wn) && !$!{EAGAIN};
  });

  my $wn = syswrite($w, 'x');
  die "pipe_churn initial syswrite: $!" if !defined $wn;

  my $cpu0 = [times];
  my $start = monotonic();
  $loop->run;
  my $end = monotonic();
  my $cpu1 = [times];

  close $r;
  close $w;

  my $res = _base_result({ %$args, scenario => 'pipe_churn' }, $start, $end, $cpu0, $cpu1);
  $res->{events} = $events;
  $res->{callbacks} = $seen;
  $res->{events_per_second} = 0 + sprintf('%.2f', $seen / $res->{elapsed_seconds});
  return $res;
}


sub run_callback_storm ($args) {
  my $events = int($args->{events} // $args->{messages} // 1_000_000);
  my $requested_fds = int($args->{fds} // 1000);
  croak "fds must be positive" if $requested_fds <= 0;
  croak "events must be positive" if $events <= 0;

  my $loop = make_loop($args->{backend});
  my @pipes;
  my $callbacks = 0;
  my $armed = 0;
  my $buf = '';
  my $fd_cap_hit = 0;
  my $pipe_error = '';

  # Do not assume a particular ulimit.  Create as many pipe pairs as the
  # process can actually spare, up to the requested count.  This keeps the
  # phase runner useful on systems with low open-file limits.
  for (1 .. $requested_fds) {
    my ($r, $w);
    if (!pipe($r, $w)) {
      $fd_cap_hit = 1;
      $pipe_error = "$!";
      last;
    }

    set_nonblocking($r);
    set_nonblocking($w);
    push @pipes, [$r, $w];

    $loop->watch($r, read => sub ($loop, $fh, $watcher) {
      my $n = sysread($fh, $buf, 1);
      die "callback_storm sysread: $!" if !defined($n) && !$!{EAGAIN};
      return if !defined($n) || $n == 0;

      ++$callbacks;
      if ($armed < $events) {
        my $wn = syswrite($w, 'x');
        die "callback_storm syswrite: $!" if !defined($wn) && !$!{EAGAIN};
        ++$armed if defined $wn;
      }
      $loop->stop if $callbacks >= $events;
    });
  }

  croak "callback_storm could not create any pipe pairs: $pipe_error" if !@pipes;

  my $actual_fds = scalar @pipes;
  warn "callback_storm: requested $requested_fds fds, using $actual_fds due to open-file limit ($pipe_error)
"
    if $fd_cap_hit;

  my $initial = $events < $actual_fds ? $events : $actual_fds;
  for my $i (0 .. $initial - 1) {
    my $wn = syswrite($pipes[$i][1], 'x');
    die "callback_storm initial syswrite: $!" if !defined $wn;
    ++$armed;
  }

  my $cpu0 = [times];
  my $start = monotonic();
  $loop->run;
  my $end = monotonic();
  my $cpu1 = [times];

  for my $pair (@pipes) {
    close $pair->[0];
    close $pair->[1];
  }

  my $res = _base_result({ %$args, scenario => 'callback_storm' }, $start, $end, $cpu0, $cpu1);
  $res->{events} = $events;
  $res->{fds} = $actual_fds;
  $res->{requested_fds} = $requested_fds;
  $res->{fd_cap_hit} = $fd_cap_hit ? JSON::PP::true : JSON::PP::false;
  $res->{callbacks} = $callbacks;
  $res->{callbacks_per_second} = 0 + sprintf('%.2f', $callbacks / $res->{elapsed_seconds});
  return $res;
}

sub run_watcher_churn ($args) {
  my $iters = int($args->{events} // $args->{messages} // 100_000);
  my $loop = make_loop($args->{backend});
  my $cpu0 = [times];
  my $start = monotonic();
  for (1 .. $iters) {
    pipe(my $r, my $w) or croak "pipe: $!";
    set_nonblocking($r);
    my $watcher = $loop->watch($r, read => sub ($loop, $fh, $watcher) {});
    $watcher->cancel;
    close $r;
    close $w;
  }
  my $end = monotonic();
  my $cpu1 = [times];
  my $res = _base_result({ %$args, scenario => 'watcher_churn' }, $start, $end, $cpu0, $cpu1);
  $res->{watchers} = $iters;
  $res->{watchers_per_second} = 0 + sprintf('%.2f', $iters / $res->{elapsed_seconds});
  return $res;
}

sub run_timer_heap ($args) {
  my $timers = int($args->{events} // $args->{messages} // 50_000);
  my $loop = make_loop($args->{backend});
  my $fired = 0;
  my $cpu0 = [times];
  my $start = monotonic();
  for (1 .. $timers) {
    $loop->after(0, sub ($loop) {
      ++$fired;
      $loop->stop if $fired >= $timers;
    });
  }
  $loop->run;
  my $end = monotonic();
  my $cpu1 = [times];
  my $res = _base_result({ %$args, scenario => 'timer_heap' }, $start, $end, $cpu0, $cpu1);
  $res->{timers} = $timers;
  $res->{timers_per_second} = 0 + sprintf('%.2f', $timers / $res->{elapsed_seconds});
  return $res;
}

sub _run_echo_client ($host, $port, $messages, $size, $lat_path) {
  my $sock = IO::Socket::INET->new(PeerHost => $host, PeerPort => $port, Proto => 'tcp')
    or die "client connect: $!";
  $sock->setsockopt(IPPROTO_TCP, TCP_NODELAY, 1);
  my $payload = 'x' x $size;
  open my $lat, '>', $lat_path or die "write $lat_path: $!";
  for (1 .. $messages) {
    my $t0 = monotonic();
    my $off = 0;
    while ($off < $size) {
      my $n = syswrite($sock, $payload, $size - $off, $off);
      die "client write: $!" if !defined $n;
      $off += $n;
    }
    my $got = 0;
    my $buf = '';
    while ($got < $size) {
      my $n = sysread($sock, $buf, $size - $got);
      die "client read: $!" if !defined $n;
      die "client eof" if $n == 0;
      $got += $n;
    }
    my $us = int((monotonic() - $t0) * 1_000_000);
    print {$lat} "$us\n";
  }
  close $lat;
  close $sock;
  exit 0;
}

sub run_echo_tcp ($args) {
  my $clients = int($args->{clients} // 1);
  my $messages = int($args->{messages} // 1000);
  my $size = int($args->{message_size} // 64);
  my $total_messages = $clients * $messages;
  my $total_bytes = $total_messages * $size;

  my $server = IO::Socket::INET->new(LocalHost => '127.0.0.1', LocalPort => 0, Proto => 'tcp', Listen => 256, ReuseAddr => 1)
    or croak "listen: $!";
  $server->setsockopt(IPPROTO_TCP, TCP_NODELAY, 1);
  set_nonblocking($server);
  my $port = $server->sockport;

  my $loop = make_loop($args->{backend});
  my $bytes_seen = 0;
  my @connections;

  $loop->watch($server, read => sub ($loop, $fh, $watcher) {
    while (1) {
      my $client = $fh->accept;
      last if !$client && $!{EAGAIN};
      die "accept: $!" if !$client;
      $client->setsockopt(IPPROTO_TCP, TCP_NODELAY, 1);
      set_nonblocking($client);
      push @connections, $client;
      $loop->watch($client, read => sub ($loop, $cfh, $cw) {
        my $buf = '';
        while (1) {
          my $n = sysread($cfh, $buf, 8192);
          if (!defined $n) {
            die "server read: $!" if !$!{EAGAIN};
            last;
          }
          if ($n == 0) {
            $cw->cancel;
            close $cfh;
            last;
          }
          $bytes_seen += $n;
          my $off = 0;
          while ($off < $n) {
            my $wn = syswrite($cfh, $buf, $n - $off, $off);
            die "server write: $!" if !defined $wn;
            $off += $wn;
          }
          if ($bytes_seen >= $total_bytes) {
            $loop->stop;
            last;
          }
        }
      });
    }
  });

  my $tmpdir = "bench/results/echo-$$-" . int(rand(1_000_000));
  mkdir $tmpdir or croak "mkdir $tmpdir: $!";
  my @kids;
  for my $i (1 .. $clients) {
    my $path = "$tmpdir/client-$i.lat";
    my $pid = fork();
    die "fork: $!" if !defined $pid;
    if ($pid == 0) { _run_echo_client('127.0.0.1', $port, $messages, $size, $path); }
    push @kids, $pid;
  }

  my $cpu0 = [times];
  my $start = monotonic();
  $loop->run;
  my $end = monotonic();
  my $cpu1 = [times];

  my $failed = 0;
  for my $pid (@kids) {
    waitpid($pid, 0);
    $failed++ if $? != 0;
  }

  my @lat;
  for my $i (1 .. $clients) {
    my $path = "$tmpdir/client-$i.lat";
    next if !-e $path;
    open my $fh, '<', $path or next;
    while (my $line = <$fh>) { chomp $line; push @lat, int($line) if $line =~ /^\d+$/; }
    close $fh;
    unlink $path;
  }
  rmdir $tmpdir;

  my $res = _base_result({ %$args, scenario => 'echo_tcp' }, $start, $end, $cpu0, $cpu1);
  $res->{clients} = $clients;
  $res->{messages_per_client} = $messages;
  $res->{message_size} = $size;
  $res->{total_messages} = $total_messages;
  $res->{total_bytes} = $total_bytes;
  $res->{messages_per_second} = 0 + sprintf('%.2f', $total_messages / $res->{elapsed_seconds});
  $res->{mb_per_second} = 0 + sprintf('%.2f', ($total_bytes / 1048576) / $res->{elapsed_seconds});
  $res->{p50_latency_us} = percentile(\@lat, 0.50);
  $res->{p95_latency_us} = percentile(\@lat, 0.95);
  $res->{p99_latency_us} = percentile(\@lat, 0.99);
  $res->{client_failures} = $failed;
  return $res;
}

sub run_scenario ($scenario, $args) {
  $args->{scenario} = $scenario;
  return run_echo_tcp($args)      if $scenario eq 'echo_tcp';
  return run_pipe_churn($args)    if $scenario eq 'pipe_churn';
  return run_callback_storm($args) if $scenario eq 'callback_storm';
  return run_watcher_churn($args) if $scenario eq 'watcher_churn';
  return run_timer_heap($args)    if $scenario eq 'timer_heap';
  croak "unknown scenario '$scenario'";
}

sub compare_results ($before, $after) {
  my @rows;
  my @keys = qw(messages_per_second events_per_second callbacks_per_second watchers_per_second timers_per_second p50_latency_us p95_latency_us p99_latency_us elapsed_seconds user_cpu_seconds system_cpu_seconds max_rss_kb);
  for my $k (@keys) {
    next if !exists $before->{$k} || !exists $after->{$k};
    next if !defined $before->{$k} || !defined $after->{$k};
    next if $before->{$k} !~ /^-?\d+(?:\.\d+)?$/ || $after->{$k} !~ /^-?\d+(?:\.\d+)?$/;
    my $delta = $after->{$k} - $before->{$k};
    my $pct = $before->{$k} == 0 ? undef : ($delta / $before->{$k}) * 100;
    push @rows, [$k, $before->{$k}, $after->{$k}, $delta, defined($pct) ? sprintf('%.2f%%', $pct) : 'n/a'];
  }
  return \@rows;
}

1;
