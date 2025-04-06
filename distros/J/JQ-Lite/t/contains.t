use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $json = q({
  "tags": ["perl", "json", "cli"],
  "title": "jq-lite in perl"
});

my $jq = JQ::Lite->new;

my @r1 = $jq->run_query($json, 'select(.tags contains "json")');
my @r2 = $jq->run_query($json, 'select(.title contains "lite")');
my @r3 = $jq->run_query($json, 'select(.tags contains "python")');

ok(@r1, 'tags contains json');
ok(@r2, 'title contains lite');
ok(!@r3, 'tags does not contain python');

done_testing;
