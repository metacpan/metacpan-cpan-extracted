#!/usr/bin/env perl
#
# resumable_watch.pl - A watcher that survives process restarts without
# missing events. Persists the last seen revision to a file; on startup it
# watches from the revision after it, so etcd replays every change made
# while the watcher was down.
#
# Handles the compaction edge case: if the server has compacted that history
# away, the watch is cancelled with compact_revision set. We then list the
# current state of the prefix and continue from there, accepting the gap.
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
my ($watch, $retry_timer);

if ($last_rev) {
    say "[resume] last seen revision: $last_rev, replaying what came after";
    start_watch($last_rev + 1);
} else {
    say "[resume] no saved revision, listing the current state";
    relist();
}

# Persist progress periodically and on shutdown
my $persist_timer = EV::timer(5, 5, \&save_last_rev);
my $shutdown = sub {
    save_last_rev();
    say "[resume] saved revision $last_rev to $state_path on shutdown";
    EV::break;
};
my $sigint  = EV::signal('INT',  $shutdown);
my $sigterm = EV::signal('TERM', $shutdown);

EV::run;

# --------------------------------------------------------------------------

sub start_watch {
    my $start_rev = shift;
    say "[watch] starting from revision $start_rev";
    $watch = $client->watch($prefix, {
        prefix          => 1,
        start_revision  => $start_rev,
        progress_notify => 1,
    }, sub {
        my ($r, $err) = @_;
        if ($err) {
            if ($err->{compact_revision}) {
                warn "[watch] history up to revision $err->{compact_revision}"
                    . " is compacted, listing the current state\n";
                return relist();
            }
            # Reconnects are exhausted or the server ended the watch
            warn "[watch] error: $err->{message}, retrying in 2s\n";
            $retry_timer = EV::timer(2, 0, sub { start_watch($last_rev + 1) });
            return;
        }
        for my $ev (@{$r->{events}}) {
            my $kv = $ev->{kv};
            say "[$ev->{type}] $kv->{key} = $kv->{value}";
            $last_rev = $kv->{mod_revision} if $kv->{mod_revision} > $last_rev;
        }
        # A progress notification (no events) covers everything up to its
        # revision; the created response does not, since history may still
        # be replaying
        $last_rev = $r->{header}{revision}
            if !$r->{created} && !@{$r->{events}} && $r->{header}{revision} > $last_rev;
    });
}

# Snapshot of the prefix, then watch everything after it
sub relist {
    $client->get($prefix, { prefix => 1 }, sub {
        my ($r, $err) = @_;
        if ($err) {
            warn "[resume] listing failed: $err->{message}, retrying in 2s\n";
            $retry_timer = EV::timer(2, 0, \&relist);
            return;
        }
        say "[list] $_->{key} = $_->{value}" for @{$r->{kvs}};
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
