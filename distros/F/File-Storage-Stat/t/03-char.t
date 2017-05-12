
use strict;

use Test;
use File::Storage::Stat;

BEGIN {
    plan tests => 10;
}

my $fss = File::Storage::Stat->new({FilePath => './t/testfile', Type => 'char'});

my @tests = (
	     {a => '', m => ''},
	     {a => 'as', m => '09'},
	     {a => 'as8', m => '09a'},
	     {a => '-)&$', m => 'ASHG'},
	     );

my @ret;
foreach (@tests) {
    $fss->set($_->{a}, $_->{m});
    @ret = $fss->get;
    ok($ret[0], $_->{a});
    ok($ret[1], $_->{m});
}

$fss->set('asdfg', 'asdfg');
@ret = $fss->get;
ok($ret[0], '');
ok($ret[1], '');
