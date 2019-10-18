#!perl -T
use strict;
use warnings;
use utf8;

use Debug::Filter::PrintExpr (-debug => 0);
use Test2::V0;
use IO::String;

# get the filehandle ref into our namespace and close it
our $handle;
*handle = *Debug::Filter::PrintExpr::handle;
close $handle;


# capture debug output into $result
my $result = '';
$handle = IO::String->new($result);
my $s = 1;
#${$s}
like $result, qr/^line \d+: \$s = '$s';$/, 'scalar';

$handle = IO::String->new($result = '');
my $t = 2;
{
	no warnings qw(void);
	#${$s, $t}
}
like $result, qr/^line \d+: \$s, \$t = '$t';$/, 'list in scalar context';

$handle = IO::String->new($result = '');
my @a = qw{a b};
#@{@a}
my $res = join(', ', map("'$_'", @a));
like $result, qr/^line \d+: \@a = \($res\);$/, 'array';

$handle = IO::String->new($result = '');
#${@a}
$res = scalar(@a);
like $result, qr/^line \d+: \@a = '$res';$/, 'array as scalar';

$handle = IO::String->new($result = '');
my %h = (k1 => 'v1', k2 => 'v2');
#%{%h}
like $result, qr/^line \d+: \%h = \(/, 'hash prefix';
like $result, qr/'$_' => '$h{$_}'/, 'hash item' foreach keys %h;
like $result, qr/\);$/, 'hash suffix';

$handle = IO::String->new($result = '');
#\{\%h}
like $result, qr/^line \d+:\s*$/m, 'ref prefix';
like $result, qr/\\\%h = \{$/m, 'ref expr';
like $result, qr/^\s+'$_' => '$h{$_}',?$/m, 'ref item' foreach keys %h;
like $result, qr/^\s*\};$/m, 'ref suffix';

$handle = IO::String->new($result = '');
#\{\@a, \%h}
like $result, qr/^line \d+:\s*$/m, 'ref list prefix';
like $result, qr/\(\\\@a, \\\%h\)\[$_\] = [[{]$/m, 'ref list expr' foreach (0..1);
like $result, qr/^\s*\};$/m, 'ref list suffix';

$handle = IO::String->new($result = '');
#${custom: $s}
like $result, qr/^custom: \$s = '$s';$/, 'custom label';

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

done_testing;
