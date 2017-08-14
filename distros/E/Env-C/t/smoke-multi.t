use strict;
use warnings;

use Test::More tests => 4;
use Env::C;

# we assume $ENV{USER} exists, but that might not be the case (e.g.: in
# docker).  If not present, just use root.
unless (exists $ENV{USER}) {
    $ENV{USER} = 'root';
}

my $env1 = Env::C::getallenv();
print "# ", scalar(@$env1), " env entries\n";
#print join "\n", @$env;
ok @$env1;

Env::C::setenv_multi(
    FOO  => foo  => 1,
    BAR  => bar  => 0,
    USER => toor => 0,
);
my $env2 = Env::C::getallenv();
is_deeply [ sort(@$env1, 'FOO=foo', 'BAR=bar') ], [ sort @$env2 ], "setmulti 1";

Env::C::setenv_multi(
    FOO  => foo2 => 0,
    BAR  => bar2 => 1,
    USER => toor => 1,
);
my $env3 = Env::C::getallenv();
is_deeply [ sort((grep { !/^USER=/ } @$env1), 'FOO=foo', 'BAR=bar2', 'USER=toor') ], [ sort @$env3 ], "setmulti 2";

Env::C::unsetenv_multi(qw/FOO BAR/);
my $env4 = Env::C::getallenv();
is_deeply [ sort((grep { !/^USER=/ } @$env1), 'USER=toor') ], [ sort @$env4 ], "unsetmulti";
