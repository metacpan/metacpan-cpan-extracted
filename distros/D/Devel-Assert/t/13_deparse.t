use strict;
use Test::Exception tests => 4;
use Test::More;
use Devel::Assert 'on';

throws_ok { assert(); } qr/arguments/;
throws_ok { assert(our $f = 0) } qr/failed/;
throws_ok { assert(my $f = 0) } qr/failed/;

eval{ 
    $SIG{__DIE__} = sub {our $seen++};
    assert(my $z + (my $x = 0)) 
};
is our $seen, 1;

