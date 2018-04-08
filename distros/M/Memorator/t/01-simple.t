use strict;
use Test::More;

BEGIN {
   my $ensure_modules = <<'END';
use DBD::SQLite 1.58;
use Minion::Backend::SQLite 3.003;
1;
END
   eval $ensure_modules
     or plan skip_all => 'Minion::Backend::SQLite required for tests';
}

use Minion;
use Mojo::IOLoop;
use Memorator;
use Path::Tiny;

my $testdb   = path(__FILE__ . '-test.db');
my $testfile = path(__FILE__ . '-test.txt');
$_->remove for ($testdb, $testfile);

my $minion = Minion->new(SQLite => ('sqlite:' . $testdb));
isa_ok $minion, 'Minion';
my $sq = $minion->backend->sqlite;
isa_ok $sq, 'Mojo::SQLite';
ok $sq->db->ping, 'ping database';

my $memorator = Memorator->new(
   alert_callback => sub { $testfile->append(@_) },
   minion         => $minion,
);

my $tasks = $minion->tasks;
is_deeply [sort { $a cmp $b } keys %$tasks],
  [qw< memorator_process_alert memorator_process_update >],
  'registered tasks';

{
   ok eval {
      $memorator->set_alert({id => 'whatever', epoch => (time - 1)});
      return 1;
   }, 'set_alert lives';

   $minion->perform_jobs;
   is_deeply [$testfile->lines], [qw< whatever >], 'notification';
   $testfile->remove;
}

{
   my $time = time;
   ok eval {
      $memorator->set_alert({id => 'ever', epoch => ($time + 2)});
      return 1;
   }, 'set_alert lives';
   ok eval {
      $minion->enqueue(
         memorator_process_update => [{id => 'what', epoch => ($time - 1)}]
      );
      return 1;
   }, 'enqueue lives';

   $minion->perform_jobs;
   my $after_time = time;
   SKIP: {
      skip 'platform seems a bit slow', 2
        if $after_time >= $time + 2;

      is_deeply [$testfile->lines], [qw< what >], 'notification 1';

      diag "wait 2 seconds...";
      sleep 2;
      $minion->perform_jobs;
      is_deeply [$testfile->lines], [qw< whatever >], 'notification 2';
   };

   $testfile->remove;
}

{
   my $time = time;
   ok eval {
      $memorator->set_alert({id => 'whatever', epoch => ($time + 2)});
      return 1;
   }, 'set_alert lives, but will be overridden';
   ok eval {
      $memorator->set_alert({id => 'whatever', epoch => ($time - 1)});
      return 1;
   }, 'set_alert lives, setting for immediate action';

   $minion->perform_jobs;
   my $after_time = time;
   SKIP: {
      skip 'platform seems a bit slow', 2
        if $after_time >= $time + 2;

      is_deeply [$testfile->lines], [qw< whatever >], 'notification A';

      diag "wait 2 seconds...";
      sleep 2;
      $minion->perform_jobs;
      is_deeply [$testfile->lines], [qw< whatever >], 'no new notification';
   }

   $testfile->remove;
}

my @hashes = sort { $a->{eid} cmp $b->{eid} }
  $sq->db->query('SELECT * FROM memorator_eid2jid')->hashes->each;
is_deeply \@hashes,
  [
   {id => 2, jid => 2, eid => 'ever',     active => 0},
   {id => 3, jid => 4, eid => 'what',     active => 0},
   {id => 5, jid => 6, eid => 'whatever', active => 0}
  ],
  'surviving records in database';

$testdb->remove;
done_testing();
