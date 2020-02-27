#!perl -T
use strict;
use warnings;
no warnings qw(void numeric);
use utf8;

#use Debug::Filter::PrintExpr -debug;
use Debug::Filter::PrintExpr;
use Test2::V0;
use Scalar::Util qw/dualvar isdual/;

# get the filehandle ref into our namespace and close it
our $handle;
*handle = *Debug::Filter::PrintExpr::handle;
close $handle;

my $result;

$\ = "\n";
$, = ',';

sub prepare {
	seek $handle, 0, 0;
	truncate $handle, 0;
	$result = '';
}

# capture debug output into $result
open $handle, '>', \$result or die 'cannot open memory file';
my $n = 37;
#${$n}
like $result, qr/^L\d+: \$n = $n;$/, 'numeric scalar';

prepare;
my $s = 'xxx';
#${$s}
like $result, qr/^L\d+: \$s = '$s';$/, 'string scalar';

prepare;
my $t = 2;
{
	no warnings 'void';
	#${$s, $t}
}
like $result, qr/^L\d+: \$s, \$t = $t;$/, 'list in scalar context';

prepare;
my @a = qw{a b};
#@{@a}
my $res = join(', ', map("'$_'", @a));
like $result, qr/^L\d+: \@a = \($res\);$/, 'array';

prepare;
#${@a}
$res = scalar(@a);
like $result, qr/^L\d+: \@a = $res;$/, 'array as scalar';

prepare;
my %h = (k1 => 'v1', k2 => 'v2');
#%{%h}
like $result, qr/^L\d+: \%h = \(/, 'hash prefix';
like $result, qr/'$_' => '$h{$_}'/, 'hash item' foreach keys %h;
like $result, qr/\);$/, 'hash suffix';

prepare;
#\{\%h}
like $result, qr/^L\d+: dump\(\\\%h\);$/m, 'ref prefix';
like $result, qr/^\s+\$_\[0\] = \{$/m, 'ref expr';
like $result, qr/^\s+'$_' => '$h{$_}',?$/m, 'ref item' foreach keys %h;
like $result, qr/^\s+\};$/m, 'ref suffix';

prepare;
#\{\@a, \%h}
like $result, qr/^L\d+: dump\(\\\@a, \\\%h\);$/m, 'ref list prefix';
like $result, qr/^\s+\$_\[$_\] = [[{]$/m, 'ref list expr' foreach (0..1);
like $result, qr/^\s+\};$/m, 'ref list suffix';

prepare;
my $s1 = '1';
#${custom: $s1}
like $result, qr/^custom: \$s1 = '$s1';$/, 'custom label';

prepare;
#${custom:}
like $result, qr/^custom:\s*$/, 'empty expr';

prepare;
my $lineno = __LINE__ + 1;
#${}
like $result, qr/^L$lineno:\s*$/, 'lineno';

prepare;
#${localtime}
like $result, qr/^L\d+: localtime = '\w{3} \w{3} [ 0-9:]{16}';$/, 'sub in scalar context';

prepare;
my $empty = '';
#${$empty}
like $result, qr/^L\d+: \$empty = '';$/, 'empty string';

prepare;
my $zero = 0;
#${$zero}
like $result, qr/^L\d+: \$zero = 0;$/, 'zero';

prepare;
my $int = 42;
#${$int}
like $result, qr/^L\d+: \$int = 42;$/, 'integer value';

prepare;
my $dual = dualvar(42, 'the answer');
#${$dual}
like $result, qr/^L\d+: \$dual = dualvar\(42, 'the answer'\);$/, 'dual values';

prepare;
#"{$dual}
like $result, qr/^L\d+: \$dual = 'the answer';$/, 'string value';

prepare;
#${$dual}
like $result, qr/^L\d+: \$dual = dualvar\(42, 'the answer'\);$/, 'dual values untouched';

prepare;
##{$dual}
like $result, qr/^L\d+: \$dual = 42;$/, 'numeric value';

prepare;
#${$dual}
like $result, qr/^L\d+: \$dual = dualvar\(42, 'the answer'\);$/, 'dual values untouched';

prepare;
my $sd = "1";
##{$sd}
is isdual($sd), F(), "don't dualize string";

prepare;
my $nd = 2;
#"{$nd}
is isdual($nd), F(), "don't dualize number";

prepare;
my $fstring = '3.1415962';
#${$fstring}
like $result, qr/^L\d+: \$fstring = '$fstring';$/, 'fp string';

prepare;
my $float = 3.1415962;
#${$float}
like $result, qr/^L\d+: \$float = $float;$/, 'floating point number';

prepare;
#${undef}
like $result, qr/^L\d+: undef = undef;$/, 'undef';

prepare;
#@{}
like $result, qr/^L\d+: \(\);$/, 'empty array';

prepare;
#%{}
like $result, qr/^L\d+: \(\);$/, 'empty hash';

prepare;
 ##$()
is $result, '', 'has prefix';
#${};
is $result, '', 'has suffix';

prepare;
#${ $s  }
like $result, qr/^L\d+: \$s = 'xxx';$/, 'braces and spaces';

prepare;
#${ $h{k1} }
like $result, qr/^L\d+: \$h\{k1\} = 'v1';$/, 'braces and spaces';

done_testing;
