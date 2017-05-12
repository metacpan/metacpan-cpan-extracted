
use strict;
use Test::More tests => 6;
use FindBin;

use_ok('Mail::Builder::Simple::TT');

my $tt = Mail::Builder::Simple::TT->new;

can_ok($tt, 'new');
can_ok($tt, 'process');

my $tt2 = Mail::Builder::Simple::TT->new({}, {name => 'Teddy'});

can_ok($tt2, 'new');
can_ok($tt2, 'process');

is($tt2->process('Hello [% name %]', 'scalar'), 'Hello Teddy', 'TT scalar OK');
