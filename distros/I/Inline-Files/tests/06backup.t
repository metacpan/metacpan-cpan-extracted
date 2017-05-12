use lib qw(./blib/lib ../blib/lib);
use strict;
use Test;

BEGIN {
    plan(tests => 4,
	 todo => [],
	 onfail => sub {},
	);
}

use Inline::Files -backup;

{
    local $/;
    open FILE, $0;
    my $text = <FILE>;
    close FILE;
    ok($text =~ /__MYFILE__\nOld stuff\n$/);
}

{
    local $/;
    open FILE, "$0.bak";
    my $text = <FILE>;
    close FILE;
    ok($text =~ /__MYFILE__\nOld stuff\n$/);
}

open MYFILE, '>';
print MYFILE "New stuff\n";
close \*MYFILE;

{
    local $/;
    open FILE, $0;
    my $text = <FILE>;
    close FILE;
    ok($text =~ /__MYFILE__\nNew stuff\n$/);
}

{
    local $/;
    open FILE, "$0.bak";
    my $text = <FILE>;
    close FILE;
    ok($text =~ /__MYFILE__\nOld stuff\n$/);
}

unlink "$0.bak";

__MYFILE__
Old stuff
