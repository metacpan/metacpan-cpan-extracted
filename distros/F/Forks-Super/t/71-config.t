use Test::More tests => 3;

if (${^TAINT}) {
    use Config;
    $^X = $Config::Config{perlpath};
    $ENV{PATH} = "";
    delete $ENV{ENV};
}

open T1, '>', "t/out/71a.$$.pl";
print T1 qq[
use Forks::Super CONFIG => 't/out/71a.$$.cfg';
print "MAX_PROC:\$Forks::Super::MAX_PROC\\n";
print "MAX_LOAD:\$Forks::Super::MAX_LOAD\\n";
print "ON_BUSY:\$Forks::Super::ON_BUSY\\n";
];
close T1;

open CFG, '>', "t/out/71a.$$.cfg";
print CFG q[# -- test config
max.proc=17.3
MAX_LOAD=qwerty
on_busy=bogus
];
close CFG;

my @j = qx($^X -Iblib/lib t/out/71a.$$.pl);
ok($j[0] =~ /17.3/, "respects config file directive");
ok($j[1] =~ /qwerty/, "respects improper config file directive");
ok($j[2] =~ /block|queue|fail/ && $j[2] !~ /bogus/,
   "handles improper config file directive");

unlink "t/out/71a.$$.pl";
unlink "t/out/71a.$$.cfg";

