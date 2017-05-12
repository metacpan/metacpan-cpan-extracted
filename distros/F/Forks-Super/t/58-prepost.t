use Forks::Super ':test';
use Test::More tests => 8;
use strict;
use warnings;

my ($p, $q, $r, $s) = (10, 10, 10, 10);

PREFORK {
    $p = 20;
    $q++;
};

PREFORK {
    $q = 20;
    $p++;
};

POSTFORK {
    $s = 20;
    $r++;
};

POSTFORK_PARENT {
    $r = 25;
    $s++;
};

POSTFORK_CHILD {
    $r = 15;
    $s++;
};

POSTFORK {
    $s = 25;
    $r++;
};

my $pid = fork {
    child_fh => 'out',
    sub => sub {
        print "$p,$q,$r,$s";
    }
};

ok($p == 21, 'PREFORK is FIFO');
ok($q == 20, 'PREFORK is FIFO');
ok($r == 26, 'POSTFORK is LIFO');
ok($s == 20, 'POSTFORK is LIFO');

wait;
my $string = $pid->read_stdout();
ok($string, 'got fork output');
my @t = split /,/, $string;
ok($t[0] == 21 && $t[1] == 20, "child retains correct vals of \$p,\$q");
ok($t[2] == 16, 'child ran POSTFORK_CHILD code');
ok($t[3] == 20, 'child ran POSTFORK code');

