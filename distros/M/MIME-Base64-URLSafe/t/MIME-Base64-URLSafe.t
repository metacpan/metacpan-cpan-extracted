use strict;

use Test::More tests => 17;

BEGIN { use_ok('MIME::Base64::URLSafe') };


my ($o, $e);


# normal case test

$o = "\0\0\0\0";
$e = 'AAAAAA';
is(urlsafe_b64encode($o), $e);
is(urlsafe_b64decode($e), $o);

$o = "\xff";
$e = '_w';
is(urlsafe_b64encode($o), $e);
is(urlsafe_b64decode($e), $o);

$o = "\xff\xff";
$e = '__8';
is(urlsafe_b64encode($o), $e);
is(urlsafe_b64decode($e), $o);

$o = "\xff\xff\xff";
$e = '____';
is(urlsafe_b64encode($o), $e);
is(urlsafe_b64decode($e), $o);

$o = "\xff\xff\xff\xff";
$e = '_____w';
is(urlsafe_b64encode($o), $e);
is(urlsafe_b64decode($e), $o);

$o = "\xfb";
$e = '-w';
is(urlsafe_b64encode($o), $e);
is(urlsafe_b64decode($e), $o);


# decoder padding test with spaces

is(urlsafe_b64decode(" AA"), "\0");
is(urlsafe_b64decode("\tAA"), "\0");
is(urlsafe_b64decode("\rAA"), "\0");
is(urlsafe_b64decode("\nAA"), "\0");
