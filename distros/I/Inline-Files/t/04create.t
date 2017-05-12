use lib qw(./blib/lib ../blib/lib);
use strict;
use Test;

BEGIN {
    plan(tests => 2,
	 todo => [],
	 onfail => sub {},
	);
}

use Inline::Files;

{
    local $/;
    open FILE, $0;
    my $text = <FILE>;
    close FILE;
    ok($text !~ /^__MYFILE1__$/m and
       $text !~ /^__MYFILE2__$/m
      );
}

{
    local $^W;
    open MYFILE1, '>' or die "$!";
    open MYFILE2, '>' or die "$!";
    print MYFILE1 ("one\n");
    print MYFILE2 ("two\n");
    print MYFILE1 ("three\n");
#    print MYXFILE ("four\n");
    close \*MYFILE1;
    close \*MYFILE2;
}

{
    local $/;
    open FILE, $0;
    my $text = <FILE>;
    close FILE;
    ok($text =~ /__MYFILE1__\none\nthree\n__MYFILE2__\ntwo\n$/);
}
__MYFILE1__
one
three
__MYFILE2__
two
