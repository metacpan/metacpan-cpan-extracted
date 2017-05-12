use strict;
use warnings;
use Test::More tests => 17;
use Getopt::Flex;

my $foo;
my $bar;
my $cab;

my $sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Bool',
    },
    'bar|b' => {
        'var' => \$bar,
        'type' => 'Bool',
    },
    'cab|c' => {
        'var' => \$cab,
        'type' => 'Str',
    }
};

$foo = 0;
$bar = 0;
$cab = 0;
my $op = Getopt::Flex->new({spec => $sp});
my @args = qw(-fb -c=foo);
$op->set_args(\@args);
$op->getopts();
my @va = $op->get_valid_args();
my @ia = $op->get_invalid_args();
my @ea = $op->get_extra_args();
ok($foo, '-f set to true');
ok($bar, '-b set to true');
is($cab, 'foo', '-c set to foo');
is($#va, 2, 'va contains 3 values');
is($#ia, -1, 'ia contains 0 values');
is($#ea, -1, 'ea contains 0 values');

$foo = 0;
$bar = 0;
$cab = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(-fc=foo -b);
$op->set_args(\@args);
$op->getopts();
ok($foo, '-f set to true');
ok($bar, '-b set to true');
is($cab, 'foo', '-c set to foo');

$foo = 0;
$bar = 0;
$cab = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(-fcfoo -b);
$op->set_args(\@args);
$op->getopts();
ok($foo, '-f set to true');
ok($bar, '-b set to true');
is($cab, 'foo', '-c set to foo');

$foo = 0;
$bar = 0;
$cab = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(-fc foo -b);
$op->set_args(\@args);
$op->getopts();
ok($foo, '-f set to true');
ok($bar, '-b set to true');
is($cab, 'foo', '-c set to foo');

my $cfg = {
    'non_option_mode' => 'SWITCH_RET_0',
};

$foo = 0;
$bar = 0;
$cab = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-Fc foo -b);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/illegal switch/, 'Found illegal switch');
