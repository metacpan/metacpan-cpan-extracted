use strict;
use warnings;
use Test::More tests => 2;
use Test::Output;
use Getopt::Flex;

my $foo;

my $cfg = {
	'usage' => 'foo [OPTIONS...] [FILES...]',
	'desc' => 'Use this to manage your foo files',
	'non_option_mode' => 'SWITCH_RET_0',
    'auto_help' => 1,
};

my $sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Str',
		'desc' => 'The foo value goes here',
    }
};

$foo = 'bar';
my $op = Getopt::Flex->new({spec => $sp, config => $cfg});
my @args = qw(--foo baz --help);
$op->set_args(\@args);
stdout_like { $op->getopts(); } qr/Usage: foo \[OPTIONS\.\.\.\] \[FILES\.\.\.\]/, 'auto_help correctly prints help';

$cfg = {
	'usage' => 'foo [OPTIONS...] [FILES...]',
	'desc' => 'Use this to manage your foo files',
	'non_option_mode' => 'SWITCH_RET_0',
    'auto_help' => 1,
};

$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Str',
		'desc' => 'The foo value goes here',
    }
};

$foo = 'bar';
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--derp baz --help);
$op->set_args(\@args);
stdout_like { $op->getopts(); } qr/[*]{2}ERROR[*]{2}: Encountered illegal switch derp/, 'auto_help correctly prints help';
