# vim: set ft=perl :

use strict;

use Test::More tests => 21;

use IO::NestedCapture 'CAPTURE_STDOUT';

my $capture = IO::NestedCapture->instance;

is(tied *STDOUT, undef);

$capture->start(CAPTURE_STDOUT);

ok(tied *STDOUT);

syswrite STDOUT, "  dumbledore\n", 11, 2;
printf STDOUT "%s\n", "mcgonagal";
print STDOUT "sprout\n";

IO::NestedCapture->stop(CAPTURE_STDOUT);

is(tied *STDOUT, undef);

my $out = $capture->get_last_out;

is(<$out>, "dumbledore\n");
is(<$out>, "mcgonagal\n");
is(<$out>, "sprout\n");
is(<$out>, undef);

$capture->start(CAPTURE_STDOUT);

ok(tied *STDOUT);

print STDOUT "flitwick\n";
print STDOUT "snape\n";
print STDOUT "trelawney\n";
print STDOUT "vector\n";

IO::NestedCapture->start(CAPTURE_STDOUT);

ok(tied *STDOUT);

print STDOUT "quirrel\n";
print STDOUT "lockhart\n";
print STDOUT "lupin\n";
print STDOUT "moody\n";
print STDOUT "umbridge\n";
$capture->stop(CAPTURE_STDOUT);

ok(tied *STDOUT);

$out = IO::NestedCapture->get_last_out;

is(<$out>, "quirrel\n");
is(<$out>, "lockhart\n");
is(<$out>, "lupin\n");
is(<$out>, "moody\n");
is(<$out>, "umbridge\n");
is(<$out>, undef);

$capture->stop(CAPTURE_STDOUT);

is(tied *STDOUT, undef);

$out = $capture->get_last_out;

is(<$out>, "flitwick\n");
is(<$out>, "snape\n");
is(<$out>, "trelawney\n");
is(<$out>, "vector\n");
