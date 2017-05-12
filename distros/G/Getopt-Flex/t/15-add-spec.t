use strict;
use warnings;
use Test::More tests => 2;
use Getopt::Flex;

my $foo;
my $bar;

my $cfg = {
	'usage' => 'foo [OPTIONS...] [FILES...]',
	'desc' => 'Use this to manage your foo files',
	'non_option_mode' => 'SWITCH_RET_0',
};

my $sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Str',
    }
};

my $esp = {
	'bar|b' => {
		'var' => \$bar,
		'type' => 'Str',
	}
};

$foo = 'foo';
$bar = 'bar';
my $op = Getopt::Flex->new({spec => $sp, config => $cfg});
$op->add_spec($esp);
my @args = qw(--foo baz --bar box --help);
$op->set_args(\@args);
$op->getopts();
is($foo, 'baz', '--foo set with baz');
is($bar, 'box', '--bar set with box');
