#!/usr/bin/env perl
# Apply numbered SQL migration files in order, recording successes in a
# `_migrations` table so reruns skip already-applied files. Usage:
#
#   eg/migration_runner.pl ./migrations/
#
# Each file in the directory must be named NNN_description.sql (e.g.
# 001_create_events.sql). Files are sorted lexically; the leading number
# is the version key stored in `_migrations`.
use strict;
use warnings;
use EV;
use EV::ClickHouse;
use File::Spec;

my $dir   = shift // die "Usage: $0 <migrations-dir>\n";
my $host  = $ENV{CLICKHOUSE_HOST}        // '127.0.0.1';
my $nport = $ENV{CLICKHOUSE_NATIVE_PORT} // 9000;

opendir my $dh, $dir or die "opendir $dir: $!";
my @files = sort grep { /\A\d+_.*\.sql\z/ } readdir $dh;
closedir $dh;
die "no migration files found in $dir\n" unless @files;

my $ch = EV::ClickHouse->new(
    host => $host, port => $nport, protocol => 'native',
    on_error => sub { die "error: $_[0]\n" },
);

# Bring the schema-tracking table up.
my $applied;
$ch->query(<<'SQL', sub { EV::break });
create table if not exists _migrations (
    version  String,
    applied  DateTime DEFAULT now()
) engine = MergeTree order by version
SQL
EV::run;

# Find what's already applied.
$ch->query("select version from _migrations format TabSeparated", sub {
    my ($rows) = @_;
    $applied = { map { $_->[0] => 1 } @{ $rows // [] } };
    EV::break;
});
EV::run;

# Apply each new file in order. We chain through EV::break per file so
# errors halt the whole run loud-and-clear.
for my $file (@files) {
    my ($version) = $file =~ /\A(\d+)_/;
    if ($applied->{$version}) {
        warn "[skip] $file (already applied)\n";
        next;
    }
    open my $fh, '<', File::Spec->catfile($dir, $file)
        or die "open $file: $!";
    my $sql = do { local $/; <$fh> };
    close $fh;
    warn "[apply] $file\n";
    my $err;
    $ch->query($sql, sub {
        (undef, $err) = @_;
        EV::break;
    });
    EV::run;
    die "FAILED: $file: $err\n" if $err;
    # Idempotency marker: the insert dedupe token guards against a partial
    # apply leaving the registry out of sync if the next step fails.
    $ch->insert('_migrations', [[$version, scalar localtime]],
                { idempotent => "mig-$version" }, sub {
        (undef, $err) = @_;
        EV::break;
    });
    EV::run;
    die "FAILED to record $file: $err\n" if $err;
    warn "[done]  $version\n";
}
$ch->finish;
print "All migrations applied.\n";
