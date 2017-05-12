BEGIN {
    $^W = 1;
    $| = 1;
    $SIG{INT} = sub { die };
    print "1..11\n";
}

use strict;
use IPC::Shareable;
my $t  = 1;
my $ok = 1;

# --- TIEARRAY
my @av;
tie(@av, 'IPC::Shareable', { destroy => 'yes' })
    or undef $ok;
print $ok ? "ok $t\n" : "not ok $t\n";

# --- STORE and FETCH
my @word = qw(tic tac toe);
@av = qw(tic tac toe);
++$t;
$ok = 1;
for (0 .. 2) {
    $av[$_] eq $word[$_] or undef $ok;
}
print $ok ? "ok $t\n" : "not ok $t\n";

# --- STORESIZE
++$t;
$ok = 1;
$#av = 5;
my $i = 0;
++$i for @av;
$i == 6 or undef $ok;
print $ok ? "ok $t\n" : "not ok $t\n";
++$t;
$ok = 1;
for (3 .. 5) {
    defined $av[$_] and undef $ok;
}
print $ok ? "ok $t\n" : "not ok $t\n";

# --- FETCHSIZE
++$t;
$ok = 1;
$#av == 5 or undef $ok;
print $ok ? "ok $t\n" : "not ok $t\n";

# --- CLEAR
@av = ();
++$t;
$ok = 1;
scalar @av == 0 or undef $ok;
print $ok ? "ok $t\n" : "not ok $t\n";

@av = qw(fee fie foe fum);

# --- POP
++$t;
$ok = 1;
my $fum = pop @av;
$fum eq 'fum' or undef $ok;
$#av == 2 or undef $ok;
print $ok ? "ok $t\n" : "not ok $t\n";

# --- PUSH
++$t;
$ok = 1;
push @av => $fum;
$#av == 3 or undef $ok;
$av[3] eq 'fum' or undef $ok;
print $ok ? "ok $t\n" : "not ok $t\n";

# --- SHIFT
++$t;
$ok = 1;
my $fee = shift @av;
$fee eq 'fee' or undef $ok;
$#av == 2 or undef $ok;
print $ok ? "ok $t\n" : "not ok $t\n";

# --- UNSHIFT
++$t;
$ok = 1;
unshift @av => $fee;
$#av == 3 or undef $ok;
$av[0] eq 'fee' or undef $ok;
print $ok ? "ok $t\n" : "not ok $t\n";

# --- SPLICE
++$t;
$ok = 1;
my(@gone) = splice @av, 1, 2, qw(i spliced);
$av[1]   eq 'i'        or undef $ok;
$av[2]   eq 'spliced'  or undef $ok;
$gone[0] eq 'fie'      or undef $ok;
$gone[1] eq 'foe'      or undef $ok;
print $ok ? "ok $t\n" : "not ok $t\n";

exit;
