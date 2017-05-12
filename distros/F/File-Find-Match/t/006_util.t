#!/usr/bin/perl
# vim: set ft=perl:
use strict;
use Test::More tests => 18;


use_ok('File::Find::Match::Util', qw( filename ext wildcard ));
my $fp = filename('foobar.pl');

ok($fp, "filename('foobar.pl')");

ok($fp->('foobar.pl'), 'Matches foobar.pl');
ok($fp->('bar/foobar.pl'), 'Matches bar/foobar.pl');
ok($fp->('usr/bar/foobar.pl'), 'Matches usr/bar/foobar.pl');
ok($fp->('/usr/bar/foobar.pl'), 'Matches /usr/bar/foobar.pl');
ok(! $fp->('quux.pm'), 'Does not match quux.pm');


eval { $fp->(undef) };
if ($@) {
    pass("Dies on undef argument.");
} else {
    fail("Does not die on undef argument.");
}

eval { $fp->() };
if ($@) {
    pass("Dies on no argument.");
} else {
    fail("Does not die on no argument.");
}

eval { filename(undef) };
if ($@) {
    pass("filename(undef) dies. Good");
} else {
    fail("filename(undef) does not die. Bad");
}

my $ep = ext('html');
ok($ep, "ext('html')");
ok($ep->('foobar.html'), "Matches foobar.html");
ok(! $ep->('foobar.jpeg'), "Does Match foobar.jpeg");

eval { ext() };
if ($@) {
	pass('ext() dies. Good');
} else {
	fail('ext() does not die. Bad.');
}

eval { ext(undef) };
if ($@) {
	pass('ext(undef) dies. Good');
} else {
	fail('ext(undef) does not die. Bad.');
}

eval { $ep->() };
if ($@) {
	pass("ext predicate dies. Good");
} else {
	pass("ext predicate does not die. Bad");
}

my $wp = wildcard('*.pm');
ok($wp, "wildcard('*.pm')");
ok($wp->('foobar.pm'), "Matches foobar.pm");

