#!/usr/bin/env perl
#
# resumable_watch.pl - A watcher that survives process restarts without
# missing events. Persists the last seen revision to a file; on startup,
# reads it back, lists any keys changed during downtime via a one-shot
# get(prefix=>1, revision=>) and then resumes streaming from the next
# revision.
#
# Handles the compaction edge case: if the server has compacted past our
# saved revision, the watch arrives in the *error* callback (per the POD
# documentation of watch's error semantics). We then re-list at HEAD and
# accept the gap.
#
# Try it:
#   $ perl eg/resumable_watch.pl /myapp/config/
#   $ etcdctl put /myapp/config/foo bar
#   $ ^C
#   $ etcdctl put /myapp/config/baz qux   # while we're down
#   $ perl eg/resumable_watch.pl /myapp/config/   # picks up baz
#
use v5.10;
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use EV;
use EV::Etcd;

my $prefix    = $ARGV[0] // '/myapp/config/';
my $state_dir = $ENV{RESUMABLE_WATCH_STATE_DIR} || '/tmp';
my $state_path = "$state_dir/resumable_watch_" . _safe_name($prefix) . ".rev";

my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379'], max_retries => 5);
my $last_rev = read_last_rev();

if ($last_rev) {
    say "[resume] last seen revision: $last_rev — fetching missed changes";
    fetch_gap($last_rev + 1, sub { start_watch($last_rev + 1) });
} else {
    say "[resume] no saved revision — starting from current HEAD";
    $client->get('/', { prefix => 1, count_only => 1 }, sub {
        my ($r, $err) = @_;
        die "head probe: $err->{message}\n" if $err;
        my $head = $r->{header}{revision};
        say "[resume] HEAD revision = $head";
        $last_rev = $head;
        save_last_rev($last_rev);
        start_watch($head + 1);
    });
}

# Persist progress periodically and on shutdown
my $persist_timer = EV::timer(5, 5, \&save_last_rev);
my $shutdown = sub {
    save_last_rev();
    say "[resume] saved revision $last_rev to $state_path on shutdown";
    EV::break;
    exit 0;
};
my $sigint  = EV::signal('INT',  $shutdown);
my $sigterm = EV::signal('TERM', $shutdown);

EV::run;

# --------------------------------------------------------------------------

sub fetch_gap {
    my ($from_rev, $cb) = @_;
    $client->get($prefix, { prefix => 1, revision => $from_rev }, sub {
        my ($r, $err) = @_;
        if ($err) {
            # If the saved revision was already compacted, etcd returns
            # OUT_OF_RANGE. Skip the gap: just start at HEAD.
            warn "[resume] gap fetch failed: $err->{message} — skipping gap\n";
            return $cb->();
        }
        for my $kv (@{$r->{kvs} || []}) {
            say "[gap] $kv->{key} = $kv->{value} (mod_rev=$kv->{mod_revision})";
        }
        $last_rev = $r->{header}{revision};
        $cb->();
    });
}

sub start_watch {
    my $start_rev = shift;
    say "[watch] starting from revision $start_rev";
    $client->watch($prefix, {
        prefix         => 1,
        start_revision => $start_rev,
        progress_notify => 1,
    }, sub {
        my ($r, $err) = @_;
        if ($err) {
            # Server-side cancellation (compaction-induced or otherwise).
            # POD: $err->{source} eq 'watch' and message includes the
            # compact revision when relevant.
            warn "[watch] error: $err->{message} — restarting from HEAD\n";
            $last_rev = 0;
            unlink $state_path;
            return start_over();
        }
        for my $ev (@{$r->{events} || []}) {
            my $kv = $ev->{kv};
            say "[$ev->{type}] $kv->{key} = " . ($kv->{value} // '');
            $last_rev = $kv->{mod_revision} if $kv->{mod_revision} > $last_rev;
        }
        # Progress notifications also advance the cursor without events
        $last_rev = $r->{header}{revision} if $r->{header}{revision} > $last_rev;
    });
}

my $retry_timer;
sub start_over {
    $client->get('/', { prefix => 1, count_only => 1 }, sub {
        my ($r, $err) = @_;
        if ($err) {
            warn "[resume] start_over failed: $err->{message} — retrying in 2s\n";
            # Hold the timer in a file-scoped lexical so it's not GC'd before firing.
            $retry_timer = EV::timer(2, 0, \&start_over);
            return;
        }
        $last_rev = $r->{header}{revision};
        save_last_rev();
        start_watch($last_rev + 1);
    });
}

sub read_last_rev {
    open my $fh, '<', $state_path or return 0;
    my $rev = <$fh>;
    chomp $rev if defined $rev;
    return $rev || 0;
}

sub save_last_rev {
    return unless $last_rev;
    open my $fh, '>', "$state_path.tmp" or do {
        warn "[resume] cannot save revision: $!\n";
        return;
    };
    print $fh "$last_rev\n";
    close $fh;
    rename "$state_path.tmp", $state_path;
}

sub _safe_name {
    my $s = shift;
    $s =~ s|[/]+|_|g;
    $s =~ s|^_||;
    $s =~ s|_$||;
    return $s;
}
