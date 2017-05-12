use strict;
use warnings;
use Test::More tests => 10;
use Getopt::Flex;

my $foo;
my $bar;
my @arr;
my %has;

my $cfg = {
    'long_option_mode' => 'SINGLE_OR_DOUBLE',
};

my $sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Str',
    },
    'cfoo|c' => {
        'var' => \$bar,
        'type' => 'Bool',
    }
};

$foo = '';
$bar = 0;
my $op = Getopt::Flex->new({spec => $sp, config => $cfg});
my @args = qw(--foo str -cfoo);
$op->set_args(\@args);
$op->getopts();
is($foo, 'str', '--foo set with str');
ok($bar, '-cfoo set to true');

$foo = '';
$bar = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-foo str -cfoo);
$op->set_args(\@args);
$op->getopts();
is($foo, 'str', '-foo set with str');
ok($bar, '-cfoo set to true');

$foo = '';
$bar = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-foo str -c);
$op->set_args(\@args);
$op->getopts();
is($foo, 'str', '-foo set with str');
ok($bar, '-c set to true');

$foo = '';
$bar = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-f str -c);
$op->set_args(\@args);
$op->getopts();
is($foo, 'str', '-f set with str');
ok($bar, '-c set to true');

$foo = '';
$bar = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--f str -c);
$op->set_args(\@args);
$op->getopts();
is($foo, 'str', '--f set with str');
ok($bar, '-c set to true');
