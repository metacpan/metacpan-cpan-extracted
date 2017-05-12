use Test::Simple 'no_plan';
use strict;
use lib './lib';

use Benchmark::Timer;

use File::Which;
use File::Which::Cached;






my $max = 10000;
my $t = Benchmark::Timer->new();




for ( 1 .. $max ){
   $t->start('normal_which_');
   File::Which::which('perl');
    $t->stop('normal_which_');
}








for ( 1 .. $max ){
   $t->start('cached_which_');
   File::Which::Cached::which('perl');
    $t->stop('cached_which_');
}



my $normal_which = ( $t->result('normal_which_') * $max);
my $cached_which = ( $t->result('cached_which_') * $max);
ok( $normal_which > $cached_which, 
   "lookups: $max\n normal which: $normal_which\n cached which: $cached_which");



my $report = $t->reports;
ok(1, " reports: $report" );




