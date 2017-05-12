use strict;
#use warnings;

use Test::More tests => 9;
use Env::C;

# we assume $ENV{USER} exists, but that might not be the case (e.g.: in
# docker).  If not present, just use root.
unless (exists $ENV{USER}) {
    $ENV{USER} = 'root';
}

# getenv
my $key = "USER";
my $val_orig = Env::C::getenv($key);
is $val_orig, $ENV{$key}, "getenv matches perl ENV for $key";

# unsetenv
Env::C::unsetenv($key);
my $val = Env::C::getenv($key);
is $val, undef, "$key is no longer set in C env";

# setenv
my $val_new = "foobar";
Env::C::setenv($key, $val_new);
$val = Env::C::getenv($key) || '';
is $val, $val_new, "reinstated $key in C env";

my $overwrite = "barbaz";
Env::C::setenv($key, $overwrite, 0);
$val = Env::C::getenv($key) || '';
is $val, $val_new, "do not overwrite $key with explicitly false override";

Env::C::setenv($key, $val_new, 1);
$val = Env::C::getenv($key) || '';
is $val, $val_new, "overwrite $key with explicitly true override";

# restore
Env::C::setenv($key, $val_orig);
$val = Env::C::getenv($key) || '';
is $val, $val_orig, "restored $key (using setenv with implicit override)";

my $env = Env::C::getallenv();
print "# ", scalar(@$env), " env entries\n";
#print join "\n", @$env;
ok @$env;

cmp_ok scalar @$env, '==', scalar keys %ENV;

my @perl_env = map { "$_=$ENV{$_}" } keys %ENV;
is_deeply [sort @$env], [sort @perl_env];
