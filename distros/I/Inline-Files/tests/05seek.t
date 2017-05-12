use lib qw(./blib/lib ../blib/lib);
use strict;
use Test;

BEGIN {
    plan(tests => 21,
	 todo => [],
	 onfail => sub {},
	);
}

use Inline::Files;

#1
ok(<IFILE> =~ /This is line 1/);
#2
ok(not seek IFILE, -10, 0);
#3
ok(seek IFILE, -10, 1);
#4
ok(<IFILE> =~ /line 1/);
#5
ok(seek IFILE, 20, 1);
#6
ok(<IFILE> =~ /line 3/);
#7
ok(seek IFILE, 500, 0);
#8
ok(not seek IFILE, -500, 1);
#9
ok(seek IFILE, -30, 1);
#10
ok(<IFILE> =~ /line 4/);
#11
ok(not seek IFILE, -500, 2);
#12
ok(seek IFILE, -30, 2);
#13
ok(<IFILE> =~ /line 4/);
#14
ok(seek IFILE, -30, 1);
#15
ok(<IFILE> =~ /line 3/);
#16
ok(seek IFILE, 0, 0);
#17
ok(<IFILE> =~ /line 1/);
#18
ok(seek IFILE, 16, 1);
#19
ok(<IFILE> =~ /line 3/);
#20
eval "seek IFILE, 16, 1, 0";
ok($@ =~ /Too many arguments for/);
#21
eval "seek IFILE, 16";
ok($@ =~ /Not enough arguments for/);


__IFILE__
This is line 1
This is line 2
This is line 3
This is line 4
This is line 5
