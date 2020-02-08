#!perl -T
use strict;
use warnings;
no warnings qw(void numeric);
use utf8;

use Debug::Filter::PrintExpr;
use Test2::V0;
use IO::String;
use Scalar::Util qw/dualvar/;

# get the filehandle ref into our namespace and close it
our $handle;
*handle = *Debug::Filter::PrintExpr::handle;
close $handle;


# capture debug output into $result
my $result = '';
$handle = IO::String->new($result);
my $n = 37;
#${$n}
like $result, qr/^line \d+: \$n = $n;$/, 'numeric scalar';

$handle = IO::String->new($result = '');
my $s = 'xxx';
#${$s}
like $result, qr/^line \d+: \$s = '$s';$/, 'string scalar';

$handle = IO::String->new($result = '');
my $t = 2;
{
	no warnings 'void';
	#${$s, $t}
}
like $result, qr/^line \d+: \$s, \$t = $t;$/, 'list in scalar context';

$handle = IO::String->new($result = '');
my @a = qw{a b};
#@{@a}
my $res = join(', ', map("'$_'", @a));
like $result, qr/^line \d+: \@a = \($res\);$/, 'array';

$handle = IO::String->new($result = '');
#${@a}
$res = scalar(@a);
like $result, qr/^line \d+: \@a = $res;$/, 'array as scalar';

$handle = IO::String->new($result = '');
my %h = (k1 => 'v1', k2 => 'v2');
#%{%h}
like $result, qr/^line \d+: \%h = \(/, 'hash prefix';
like $result, qr/'$_' => '$h{$_}'/, 'hash item' foreach keys %h;
like $result, qr/\);$/, 'hash suffix';

$handle = IO::String->new($result = '');
#\{\%h}
like $result, qr/^line \d+: dump\(\\\%h\);$/m, 'ref prefix';
like $result, qr/\$_\[0\] = \{$/m, 'ref expr';
like $result, qr/^\s+'$_' => '$h{$_}',?$/m, 'ref item' foreach keys %h;
like $result, qr/^\s*\};$/m, 'ref suffix';

$handle = IO::String->new($result = '');
#\{\@a, \%h}
like $result, qr/^line \d+: dump\(\\\@a, \\\%h\);$/m, 'ref list prefix';
like $result, qr/^\$_\[$_\] = [[{]$/m, 'ref list expr' foreach (0..1);
like $result, qr/^\s*\};$/m, 'ref list suffix';

$handle = IO::String->new($result = '');
my $s1 = '1';
#${custom: $s1}
like $result, qr/^custom: \$s1 = '$s1';$/, 'custom label';

$handle = IO::String->new($result = '');
#${custom:}
like $result, qr/^custom:\s*$/, 'empty expr';

$handle = IO::String->new($result = '');
my $lineno = __LINE__ + 1;
#${}
like $result, qr/^line $lineno:\s*$/, 'lineno';

$handle = IO::String->new($result = '');
#${localtime}
like $result, qr/^line \d+: localtime = '\w{3} \w{3} [ 0-9:]{16}';$/, 'sub in scalar context';

$handle = IO::String->new($result = '');
my $empty = '';
#${$empty}
like $result, qr/^line \d+: \$empty = '';$/, 'empty string';

$handle = IO::String->new($result = '');
my $zero = 0;
#${$zero}
like $result, qr/^line \d+: \$zero = 0;$/, 'zero';

$handle = IO::String->new($result = '');
my $int = 42;
#${$int}
like $result, qr/^line \d+: \$int = 42;$/, 'integer value';

$handle = IO::String->new($result = '');
my $dual = dualvar(42, 'the answer');
#${$dual}
like $result, qr/^line \d+: \$dual = 'the answer' : 42;$/, 'dual values';

$handle = IO::String->new($result = '');
#"{$dual}
like $result, qr/^line \d+: \$dual = 'the answer';$/, 'string value';

$handle = IO::String->new($result = '');
##{$dual}
like $result, qr/^line \d+: \$dual = 42;$/, 'numeric value';

$handle = IO::String->new($result = '');
my $fstring = '3.1415962';
#${$fstring}
like $result, qr/^line \d+: \$fstring = '$fstring';$/, 'fp string';

$handle = IO::String->new($result = '');
my $float = 3.1415962;
#${$float}
like $result, qr/^line \d+: \$float = $float;$/, 'floating point number';

$handle = IO::String->new($result = '');

#${undef}
like $result, qr/^line \d+: undef = undef;$/, 'undef';

done_testing;
