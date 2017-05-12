BEGIN {
    $^W = 1;
    $| = 1;
    $SIG{INT} = sub { die };
    print "1..5\n";
}

use strict;
use IPC::Shareable;
my $t  = 1;
my $ok = 1;

# --- TIESCALAR
my $sv;
tie($sv, 'IPC::Shareable', { destroy => 'yes' })
    or undef $ok;
print $ok ? "ok $t\n" : "not ok $t\n";

# --- scalar STORE and FETCH
++$t;
$ok = 1;
$sv = 'foo';
($sv eq 'foo') or undef $ok;
print $ok ? "ok $t\n" : "not ok $t\n";

# This is a regression test for the
# bug fixed by using Scalar::Util::reftype
# instead of looking for HASH, SCALAR, ARRAY
# in the stringified version of the scalar.
foreach my $mod (qw/HASH SCALAR ARRAY/){
    # --- TIESCALAR
    my $sv;
    tie($sv, 'IPC::Shareable', { destroy => 'yes' })
        or die ('this was not expected to die here');

    # --- scalar STORE and FETCH
    ++$t;
    $ok = 1;
    $sv = $mod.'foo';
    ($sv eq $mod.'foo') or undef $ok;
    print $ok ? "ok $t\n" : "not ok $t\n";
}
# --- Done!
exit;
