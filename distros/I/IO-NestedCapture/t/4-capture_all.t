# vim: set ft=perl :

use strict;

use Test::More tests => 68;

use IO::NestedCapture ':constants';

my $capture = IO::NestedCapture->instance;

my $in = $capture->get_next_in;

is(tied *STDIN, undef);
is(tied *STDOUT, undef);
is(tied *STDERR, undef);

print $in "black\n";
print $in "bones\n";

$capture->start(CAPTURE_ALL);

ok(tied *STDIN);
ok(tied *STDOUT);
ok(tied *STDERR);

print STDOUT "dearborn\n";
is(<STDIN>, "black\n");
print STDERR "diggle\n";
is(<STDIN>, "bones\n");
print STDERR "doge\n";
is(<STDIN>, undef);
$capture->stop(CAPTURE_ALL);

is(tied *STDIN, undef);
is(tied *STDOUT, undef);
is(tied *STDERR, undef);


my $out = $capture->get_last_out;
my $err = $capture->get_last_err;

is(<$out>, "dearborn\n");
is(<$out>, undef);
is(<$err>, "diggle\n");
is(<$err>, "doge\n");
is(<$err>, undef);

$in = $capture->get_next_in;

print $in "dumbledore\n";
print $in "fenwick\n";

IO::NestedCapture->start(CAPTURE_STDIN);

ok(tied *STDIN);
is(tied *STDOUT, undef);
is(tied *STDERR, undef);

is(<STDIN>, "dumbledore\n");

$capture->start(CAPTURE_STDOUT);

ok(tied *STDIN);
ok(tied *STDOUT);
is(tied *STDERR, undef);

print STDOUT "hagrid\n";

$capture->start(CAPTURE_STDERR);

ok(tied *STDIN);
ok(tied *STDOUT);
ok(tied *STDERR);

print STDERR "longbottom\n";
print STDOUT "lupin\n";

$capture->start(CAPTURE_STDOUT);

ok(tied *STDIN);
ok(tied *STDOUT);
ok(tied *STDERR);

print STDOUT "mcgonagall\n";
print STDERR "mckinnon\n";

IO::NestedCapture->start(CAPTURE_STDERR);

ok(tied *STDIN);
ok(tied *STDOUT);
ok(tied *STDERR);

print STDOUT "meadowes\n";
print STDERR "moody\n";

$in = $capture->get_next_in;

print $in "pettigrew\n";
print $in "podmore\n";

$capture->start(CAPTURE_STDIN);

ok(tied *STDIN);
ok(tied *STDOUT);
ok(tied *STDERR);

print STDOUT "potter\n";
is(<STDIN>, "pettigrew\n");
print STDERR "prewett\n";
is(<STDIN>, "podmore\n");
print STDOUT "snape\n";
is(<STDIN>, undef);
print STDERR "vance\n";

$capture->stop(CAPTURE_STDIN);

ok(tied *STDIN);
ok(tied *STDOUT);
ok(tied *STDERR);

is(<STDIN>, "fenwick\n");
is(<STDIN>, undef);

$capture->stop(CAPTURE_ALL);

is(tied *STDIN, undef);
ok(tied *STDOUT);
ok(tied *STDERR);

$out = IO::NestedCapture->get_last_out;
$err = $capture->get_last_err;

is(<$out>, "mcgonagall\n");
is(<$out>, "meadowes\n");
is(<$out>, "potter\n");
is(<$out>, "snape\n");
is(<$out>, undef);

is(<$err>, "moody\n");
is(<$err>, "prewett\n");
is(<$err>, "vance\n");
is(<$err>, undef);

$capture->stop(CAPTURE_STDERR);

is(tied *STDIN, undef);
ok(tied *STDOUT);
is(tied *STDERR, undef);

$err = $capture->get_last_err;

is(<$err>, "longbottom\n");
is(<$err>, "mckinnon\n");
is(<$err>, undef);

IO::NestedCapture->stop(CAPTURE_STDOUT);

is(tied *STDIN, undef);
is(tied *STDOUT, undef);
is(tied *STDERR, undef);

$out = $capture->get_last_out;

is(<$out>, "hagrid\n");
is(<$out>, "lupin\n");
is(<$out>, undef);
