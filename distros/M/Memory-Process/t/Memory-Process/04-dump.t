# Pragmas.
use strict;
use warnings;

# Modules.
use Memory::Process;
use IO::CaptureOutput qw(capture);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $obj = Memory::Process->new;
my ($stdout, $stderr);
my $ret;
capture sub {
	$ret = $obj->dump;
	return;
} => \$stdout, \$stderr;
is($ret, 1, 'Get dump() return code.');
is($stdout, '', 'No stdout output without recorded stays.');
is($stderr, '', 'No stderr output without recorded stays.');

# Test.
$obj = Memory::Process->new;
$obj->record('1');
sleep 1;
$obj->record('2');
undef $stdout;
undef $stderr;
capture sub {
	$ret = $obj->dump;
	return;
} => \$stdout, \$stderr;
my $right_ret = qr{
time\s+vsz\ \(\s*diff\)\s+rss\ \(\s*diff\)\ shared\ \(\s*diff\)\s+code\ \(\s*diff\)\s+data\ \(\s*diff\)\s*
0[\d\s]+\([\d\s]+\)[\d\s]+\([\d\s]+\)[\d\s]+\([\d\s]+\)[\d\s]+\([\d\s]+\)[\d\s]+\([\d\s]+\)[\d\s]+
1[\d\s]+\([\d\s]+\)[\d\s]+\([\d\s]+\)[\d\s]+\([\d\s]+\)[\d\s]+\([\d\s]+\)[\d\s]+\([\d\s]+\)[\d\s]+
}x;
is($ret, 1, 'Get dump() return code.');
is($stdout, '', 'No stdout output on recorded stays.');
like($stderr, $right_ret, 'Stderr output on recorded stays.');
