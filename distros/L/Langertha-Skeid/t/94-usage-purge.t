#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Mojo;
use File::Temp qw(tempdir);
use FindBin;
use JSON::MaybeXS qw(decode_json);
use Langertha::Skeid;
use Langertha::Skeid::Proxy;
use Langertha::Skeid::UsageStore;

# Deleting usage data (skeid k122): the usage events of an organisation's key ids, on an erasure
# request, and the events past a retention period. A dry run counts, a purge is idempotent, and
# the answer is something a caller can record.

my $dir = tempdir(CLEANUP => 1);
my $ADMIN = 'sk-admin-test-only';
my ($ORG_A, $ORG_B, $OTHER) = map { 'k_' . ($_ x 40) } qw( a b c );

sub seed {
  my ($skeid) = @_;
  my $n = 0;
  for my $row ([$ORG_A, '2020-01-01T00:00:00Z'], [$ORG_A, '2026-11-01T00:00:00Z'],
               [$ORG_B, '2026-11-01T00:00:00Z'], [$OTHER, '2020-01-01T00:00:00Z'],
               [$OTHER, '2026-11-01T00:00:00Z']) {
    my ($id, $at) = @$row;
    $skeid->call_function('usage.record', { created_at => $at, request_id => 'r' . $n++,
      api_key_id => $id, model => 'm', ok => 1, status_code => 200 })->{ok} or die 'seed failed';
  }
}
sub count_for { $_[0]->call_function('usage.report', { api_key_id => $_[1] })->{totals}{requests} }
sub total     { $_[0]->call_function('usage.report', {})->{totals}{requests} }

# --- the request is checked before any store sees it ---
for my $case (
  [ {},                                           qr/needs api_key_ids, before, or both/ ],
  [ { api_key_ids => [] },                        qr/non-empty list/ ],
  [ { api_key_ids => 'k_x' },                     qr/non-empty list/ ],
  [ { api_key_ids => [ undef ] },                 qr/non-empty list/ ],
  [ { before => '2026-01-01' },                   qr/ISO 8601 UTC/ ],
  [ { before => "2026-01-01T00:00:00Z' OR 1=1" }, qr/ISO 8601 UTC/ ],
) {
  my ($args, $error) = @$case;
  my ($request, $why) = Langertha::Skeid::UsageStore->purge_request($args);
  ok !$request, 'a malformed purge request is refused';
  like $why, $error, "... ($error)";
}

for my $store (
  [ sqlite         => { backend => 'sqlite',  sqlite_path => "$dir/usage.sqlite" } ],
  [ 'jsonlog dir'  => { backend => 'jsonlog', log_path => "$dir/events/", mode => 'dir' } ],
  [ 'jsonlog file' => { backend => 'jsonlog', log_path => "$dir/usage.jsonl", mode => 'file' } ],
) {
  my ($label, $cfg) = @$store;
  mkdir "$dir/events" if $cfg->{mode} && $cfg->{mode} eq 'dir';
  SKIP: {
    skip 'DBD::SQLite not available', 1 if $cfg->{backend} eq 'sqlite' && !eval { require DBD::SQLite; 1 };
    subtest $label => sub {
      my $skeid = Langertha::Skeid->new(usage_store => $cfg);
      seed($skeid);
      is total($skeid), 5, 'five events';

      my $dry = $skeid->purge_usage(api_key_ids => [ $ORG_A, $ORG_B ], dry_run => 1);
      is $dry->{ok}, 1, 'a dry run succeeds';
      is $dry->{matched}, 3, 'and counts the organisation\'s events';
      is $dry->{deleted}, 0, 'without deleting';
      is total($skeid), 5, 'all five are still there';
      is $dry->{api_key_ids}, 2, 'the answer says how many key ids were asked for';
      like $dry->{purged_at}, qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/, 'and when';
      is $dry->{backend}, $cfg->{backend}, 'and by which store';

      my $done = $skeid->purge_usage(api_key_ids => [ $ORG_A, $ORG_B ]);
      is_deeply [ @{$done}{qw( ok matched deleted dry_run )} ], [ 1, 3, 3, 0 ], 'the purge deletes them';
      is count_for($skeid, $ORG_A) + count_for($skeid, $ORG_B), 0, 'none of the organisation\'s events is left';
      is count_for($skeid, $OTHER), 2, 'other keys keep theirs';

      my $again = $skeid->purge_usage(api_key_ids => [ $ORG_A, $ORG_B ]);
      is_deeply [ @{$again}{qw( ok matched deleted )} ], [ 1, 0, 0 ], 'repeated, it is idempotent';

      my $old = $skeid->purge_usage(before => '2026-01-01T00:00:00Z');
      is_deeply [ @{$old}{qw( ok deleted )} ], [ 1, 1 ], 'before deletes what is older';
      is total($skeid), 1, 'the newer event stays';

      ok $skeid->call_function('usage.record', { api_key_id => $OTHER, model => 'm', ok => 1, status_code => 200 })->{ok},
        'the store still takes events after a purge';
      is total($skeid), 2, 'and reports them';
    };
  }
}

# --- retention_days: the cut-off, and a malformed one fails the load ---
{
  my $skeid = Langertha::Skeid->new(usage_store => { backend => 'jsonlog', log_path => "$dir/r.jsonl", retention_days => 30 });
  my $before = $skeid->usage_retention_before;
  like $before, qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/, 'retention_days gives a cut-off';
  is(Langertha::Skeid->new->usage_retention_before, undef, 'no retention, no cut-off');
  ok !eval { Langertha::Skeid->new(usage_store => { backend => 'jsonlog', log_path => "$dir/r.jsonl", retention_days => 0 }); 1 },
    'retention_days 0 fails the load';
  ok !eval { Langertha::Skeid->new(usage_store => { backend => 'jsonlog', log_path => "$dir/r.jsonl", retention_days => '1.5' }); 1 },
    'as does a fraction';
}

# --- a DBI store refuses while its spool holds events that would bring rows back ---
SKIP: {
  skip 'DBD::SQLite not available', 3 unless eval { require DBD::SQLite; 1 };
  mkdir "$dir/spool";
  my $skeid = Langertha::Skeid->new(usage_store => { backend => 'sqlite',
    sqlite_path => "$dir/spooled.sqlite", spool_dir => "$dir/spool" });
  open my $fh, '>', "$dir/spool/usage-spool-host-1.jsonl" or die $!;
  print {$fh} qq({"api_key_id":"$ORG_A"}\n);
  close $fh;
  my $res = $skeid->purge_usage(api_key_ids => [ $ORG_A ]);
  is $res->{ok}, 0, 'a purge is refused while the spool holds events';
  like $res->{error}, qr/spool holds 1 file/, 'and says why';
  unlink "$dir/spool/usage-spool-host-1.jsonl";
  is $skeid->purge_usage(api_key_ids => [ $ORG_A ])->{ok}, 1, 'and goes through once it is empty';
}

# --- a store that cannot purge says so ---
{
  my $skeid = Langertha::Skeid->new(store_usage_event => sub { { ok => 1 } });
  my $res = $skeid->purge_usage(api_key_ids => [ $ORG_A ]);
  is $res->{ok}, 0, 'a callback sink cannot purge';
}

# --- POST /skeid/usage/purge ---
{
  my $skeid = Langertha::Skeid->new(admin_api_key => $ADMIN,
    usage_store => { backend => 'jsonlog', log_path => "$dir/admin.jsonl", mode => 'file' });
  seed($skeid);
  my $t = Test::Mojo->new(Langertha::Skeid::Proxy->build_app(skeid => $skeid));
  $t->app->log->level('fatal');
  my %auth = (Authorization => "Bearer $ADMIN");
  $t->post_ok('/skeid/usage/purge' => \%auth => json => { api_key_ids => [ $ORG_A ], dry_run => \1 })
    ->status_is(200)->json_is('/ok' => 1)->json_is('/matched' => 2)->json_is('/deleted' => 0);
  $t->post_ok('/skeid/usage/purge' => \%auth => json => { api_key_ids => [ $ORG_A ] })
    ->status_is(200)->json_is('/deleted' => 2);
  $t->post_ok('/skeid/usage/purge' => \%auth => json => {})->status_is(400)->json_is('/ok' => 0);
  $t->post_ok('/skeid/usage/purge' => json => { api_key_ids => [ $ORG_B ] })->status_is(401);
  is count_for($skeid, $ORG_B), 1, 'an unauthenticated purge deletes nothing';
}

# --- skeid usage-purge ---
{
  my $log = "$dir/cli.jsonl";
  my $config = "$dir/cli.yaml";
  open my $fh, '>', $config or die $!;
  print {$fh} "usage_store:\n  backend: jsonlog\n  log_path: $log\n  mode: file\n  retention_days: 365\n";
  close $fh;
  seed(Langertha::Skeid->new(config_file => $config));

  my $bin = "$FindBin::Bin/../bin/skeid";
  my $out = qx{$^X -Ilib $bin usage-purge --config $config --dry-run $ORG_A 2>&1};
  is $? >> 8, 0, 'usage-purge --dry-run exits 0';
  my $res = eval { decode_json($out) } || {};
  is $res->{matched}, 2, 'and prints the count as JSON';

  $out = qx{$^X -Ilib $bin usage-purge --config $config --retention 2>&1};
  is $? >> 8, 0, 'usage-purge --retention exits 0';
  $res = eval { decode_json($out) } || {};
  is $res->{deleted}, 2, 'and deletes the events past the retention';
  like $res->{before}, qr/\A\d{4}-/, 'naming the cut-off';

  $out = qx{$^X -Ilib $bin usage-purge --config $config 2>&1};
  is $? >> 8, 2, 'without key ids or a time it refuses (exit 2)';

  chmod 0600, $log;
  seed(Langertha::Skeid->new(config_file => $config));
  qx{$^X -Ilib $bin usage-purge --config $config $ORG_A 2>&1};
  is((stat $log)[2] & 07777, 0600, 'a purge keeps the usage log\'s permissions');
}

done_testing;
