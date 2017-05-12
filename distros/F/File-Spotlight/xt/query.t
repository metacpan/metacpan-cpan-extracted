use strict;
use Test::More;
use File::Spotlight;

my @list = File::Spotlight->new("t/textapp.savedSearch")->list;
diag join("\n", @list);
ok @list > 0;

done_testing;
