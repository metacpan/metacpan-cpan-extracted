use lib qw(./blib/lib ../blib/lib);
use strict;
use Test::More;

BEGIN {
    plan(tests => 12,
	 todo => [],
	 onfail => sub {},
	);
}

use Inline::Files;
use vars '%MYFILE';

{
    local $/;
    ok(!defined $MYFILE{file});
    ok(!defined $MYFILE{line});
    ok(!defined $MYFILE{offset});
    ok($MYFILE{writable});
    ok(!defined $MYFILE{other});
    open MYFILE;
    like($MYFILE{file} => qr/07hash.t$/);
    is($MYFILE{line} => 34);
    is($MYFILE{offset} => 654);
    ok($MYFILE{writable});
    ok(!eval{ $MYFILE{writable}=0; 1 });
    ok(!defined $MYFILE{other});
    my $text = <MYFILE>;
    close MYFILE;
    like($text => qr/Old stuff\n$/);
}

__MYFILE__
Old stuff
