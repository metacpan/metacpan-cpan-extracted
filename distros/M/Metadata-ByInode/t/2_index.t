use Test::Simple qw 'no_plan';
use strict;
use lib './lib';
use Metadata::ByInode;
use Cwd;

my $abs_index = cwd().'/t/misc';

my $m;
ok ( $m = new Metadata::ByInode({ abs_dbfile => './t/mbitest.db' }), 'object instanced' );


my $indexed_run1 = $m->index($abs_index);
ok( $indexed_run1, "index run 1: $indexed_run1");


### search tests...

my $RESULT;
ok( $RESULT = $m->search({'filename:exact' => 'file2.x', abs_loc=> $abs_index }),'search exact one key');
ok( $m->results_count == 1, "Results count should be 1, it is ".$m->results_count );


ok( $RESULT = $m->search({'filename:like' => 'pm', abs_loc=> $abs_index }),'search one key');
### $RESULT

my $count = $m->results_count;
ok($count == 3,"results count $count should be 3 pm files");
#ok($count);
ok($RESULT = $m->search_results,'search results in array form');
### $RESULT

ok( $RESULT = $m->search({filename => 'Coop.pm', abs_loc => $abs_index}),'search one key');
### $RESULT

#ok($m->results_count);
ok( $m->results_count == 1,'results count, 1 pm file');
ok( $RESULT = $m->search_results,'search results in array form');
### $RESULT


mkdir './t/misc/haha';
open(FILE,">./t/misc/haha/hahaha");
close FILE;

my $reindex1 = $m->index($abs_index);
ok( $reindex1, "reindex1: $reindex1");

$m->search({ filename => 'hahaha'});
ok($m->results_count == 1, 'one file matching');


# NEED TO WAIT FOR INDEXER TO TAKE OUT , to recognize as old.
sleep 1; # sleeps for 1 sec

unlink './t/misc/haha/hahaha';


my $reindexed2 = $m->index($abs_index);
ok( $reindexed2, "reindexed: $reindexed2");

my $srch= $m->search({ filename => 'hahaha'});
### $srch
ok( $m->results_count == 0 , 'no file matching');


rmdir './t/haha';


unlink './t/mbitest.db';


