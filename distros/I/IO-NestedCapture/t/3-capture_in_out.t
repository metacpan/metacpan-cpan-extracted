# vim: set ft=perl :

use strict;

use Test::More tests => 40;

use IO::NestedCapture 'CAPTURE_STDIN', 'CAPTURE_STDOUT';

is(tied *STDIN, undef);
is(tied *STDOUT, undef);

IO::NestedCapture->start(CAPTURE_STDOUT);

is(tied *STDIN, undef);
ok(tied *STDOUT);

my $capture = IO::NestedCapture->instance;

print STDOUT "alecto\n";
print STDOUT "amycus\n";
print STDOUT "avery\n";
print STDOUT "crabbe\n";
$capture->stop(CAPTURE_STDOUT);

is(tied *STDIN, undef);
is(tied *STDOUT, undef);

IO::NestedCapture->set_next_in($capture->get_last_out);

$capture->start(CAPTURE_STDIN);

ok(tied *STDIN);
is(tied *STDOUT, undef);

is(<STDIN>, "alecto\n");
is(<STDIN>, "amycus\n");
is(<STDIN>, "avery\n");
is(<STDIN>, "crabbe\n");
is(<STDIN>, undef);
$capture->stop(CAPTURE_STDIN);

is(tied *STDIN, undef);
is(tied *STDOUT, undef);

my $in = $capture->get_next_in;

print $in "dolohov\n";
print $in "goyle\n";
print $in "greyback\n";
print $in "jugson\n";

$capture->start(CAPTURE_STDIN | CAPTURE_STDOUT);

ok(tied *STDIN);
ok(tied *STDOUT);

print STDOUT "lestrange\n";
print STDOUT "macnair\n";

$in = IO::NestedCapture->get_next_in;

print $in "malfoy\n";
print $in "mulciber\n";
print $in "nott\n";
print $in "pettigrew\n";

is(<STDIN>, "dolohov\n");
is(<STDIN>, "goyle\n");

$capture->start(CAPTURE_STDIN | CAPTURE_STDOUT);

ok(tied *STDIN);
ok(tied *STDOUT);

is(<STDIN>, "malfoy\n");
print STDOUT "rookwood\n";
is(<STDIN>, "mulciber\n");
print STDOUT "snape\n";
is(<STDIN>, "nott\n");
print STDOUT "travers\n";
$capture->stop(CAPTURE_STDIN | CAPTURE_STDOUT);

ok(tied *STDIN);
ok(tied *STDOUT);

is(<STDIN>, "greyback\n");
is(<STDIN>, "jugson\n");
is(<STDIN>, undef);

my $out = IO::NestedCapture->get_last_out;

is(<$out>, "rookwood\n");
is(<$out>, "snape\n");

$capture->stop(CAPTURE_STDOUT);

ok(tied *STDIN);
is(tied *STDOUT, undef);

is(<$out>, "travers\n");
is(<$out>, undef);

$out = $capture->get_last_out;

is(<$out>, "lestrange\n");

IO::NestedCapture->stop(CAPTURE_STDIN);

is(tied *STDIN, undef);
is(tied *STDOUT, undef);

is(<$out>, "macnair\n");
is(<$out>, undef);
