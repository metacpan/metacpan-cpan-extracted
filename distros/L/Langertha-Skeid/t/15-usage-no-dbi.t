use strict;
use warnings;
use Test::More;

use Langertha::Skeid;

# Create a Skeid instance with no usage_store configured and no usage_db_path.
# This simulates the case where DBI is not needed.
my $skeid = Langertha::Skeid->new;

# record_usage should not crash — returns error dict
my $rec = $skeid->call_function('usage.record', {
  model   => 'test-model',
  metrics => { usage => { input => 10, output => 5, total => 15 } },
});
ok(!$rec->{ok}, 'record_usage returns not-ok when no backend configured');
like($rec->{error}, qr/not configured/, 'error message mentions not configured');

# usage_report should not crash — returns error dict
my $rep = $skeid->call_function('usage.report', {});
ok(!$rep->{ok}, 'usage_report returns not-ok when no backend configured');
is($rep->{enabled}, 0, 'reports disabled');

done_testing;
