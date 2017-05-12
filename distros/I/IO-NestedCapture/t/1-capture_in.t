# vim: set ft=perl :

use strict;

use Test::More tests => 32;

use IO::NestedCapture 'CAPTURE_STDIN';

my $capture = IO::NestedCapture->instance;

my $in = $capture->get_next_in;
print $in "harry\n";
print $in "dudley\n";

$in = IO::NestedCapture->get_next_in;
print $in "vernon\n";
print $in "petunia\n";

is(tied *STDIN, undef);

$capture->start(CAPTURE_STDIN);

ok(tied *STDIN);

my $buf;
read STDIN, $buf, 6, 0;
is($buf, "harry\n");
is(getc STDIN, 'd');
is(getc STDIN, 'u');
is(getc STDIN, 'd');
is(getc STDIN, 'l');
is(getc STDIN, 'e');
is(getc STDIN, 'y');
is(getc STDIN, "\n");
is(<STDIN>, "vernon\n");
is(<STDIN>, "petunia\n");
is(<STDIN>, undef);

$capture->stop(CAPTURE_STDIN);

is(tied *STDIN, undef);

$in = $capture->get_next_in;

print $in "ginny\n";
print $in "ron\n";
print $in "fred\n";
print $in "george\n";
print $in "percy\n";
print $in "bill\n";
print $in "charlie\n";
print $in "molly\n";
print $in "arthur\n";

IO::NestedCapture->start(CAPTURE_STDIN);

ok(tied *STDIN);

is(<STDIN>, "ginny\n");
is(<STDIN>, "ron\n");

$in = $capture->get_next_in;

print $in "draco\n";
print $in "lucius\n";
print $in "narcissa\n";

is(<STDIN>, "fred\n");
is(<STDIN>, "george\n");

$capture->start(CAPTURE_STDIN);

ok(tied *STDIN);

is(<STDIN>, "draco\n");
is(<STDIN>, "lucius\n");
is(<STDIN>, "narcissa\n");
is(<STDIN>, undef);

IO::NestedCapture->stop(CAPTURE_STDIN);

ok(tied *STDIN);

is(<STDIN>, "percy\n");
is(<STDIN>, "bill\n");
is(<STDIN>, "charlie\n");
is(<STDIN>, "molly\n");
is(<STDIN>, "arthur\n");
is(<STDIN>, undef);

close STDIN;

$capture->stop(CAPTURE_STDIN);

is(tied *STDIN, undef);
