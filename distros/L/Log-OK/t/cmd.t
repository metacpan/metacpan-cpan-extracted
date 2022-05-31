use strict;
use warnings;

use Test::More tests=>7;
use File::Basename qw<dirname>;
BEGIN {
        use_ok "Log::OK"
};
my $dir=dirname __FILE__;

my $fh;
unless(open $fh, "-|","$^X $dir/cmd.t.p --verbose info"){
        die "error opening process";
}

my @results=<$fh>;
print @results;
ok $results[0]==1;
ok $results[1]==1;
ok $results[2]==1;
ok $results[3]==1;
ok $results[4]==0;
ok $results[5]==0;
