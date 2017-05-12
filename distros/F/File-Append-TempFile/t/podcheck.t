# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl podcheck.t'

use Pod::Checker;
use Test::More tests => 6;

my ($c, $res);

$c = new Pod::Checker '-warnings' => 1;
ok $c, 'The Pod::Checker object was created';
$res = $c->parse_from_file('lib/File/Append/TempFile.pm', \*STDERR);
is $c->num_errors(), 0, 'The File::Append::TempFile POD has no errors';
if ($c->can('num_warnings')) {
	is $c->num_warnings(), 0,
	    'The File::Append::TempFile POD has no warnings at level 1';
} else {
	skip 'Pod::Checker does not support num_warnings', 1;
}

$c = new Pod::Checker '-warnings' => 5;
ok $c, 'The Pod::Checker object was created';
$res = $c->parse_from_file('lib/File/Append/TempFile.pm', \*STDERR);
is $c->num_errors(), 0, 'The File::Append::TempFile POD has no errors';
if ($c->can('num_warnings')) {
	is $c->num_warnings(), 0,
	    'The File::Append::TempFile POD has no warnings at level 5';
} else {
	skip 'Pod::Checker does not support num_warnings', 1;
}
