BEGIN {
    $^W = 1;
    $| = 1;
    $SIG{INT} = sub { die };
    print "1..10\n";
}

use strict;
use IPC::Shareable;
my $t  = 1;
my $ok = 1;

# --- TIEHASH
my %hv;
tie(%hv, 'IPC::Shareable', { 'destroy' => 'yes' })
    or undef $ok;
print $ok ? "ok $t\n" : "not ok $t\n";

# --- Assign a few values (STORE, FETCH)
my %check;
++$t;
$ok = 1;
my @k = map { ('a' .. 'z')[int(rand(26))] } (0 .. 9);
my @v = map { ('A' .. 'Z')[int(rand(26))] } (0 .. 9);
@check{@k} = @v;
while (my($k, $v) = each %check) {
    $hv{$k}    = $v;
}
while (my($k, $v) = each %check) {
    $hv{$k} eq $v or undef $ok;
}
print $ok ? "ok $t\n" : "not ok $t\n";

# --- FIRSTKEY, NEXTKEY
++$t;
$ok = 1;
my $kno = keys %check;
my $n = 0;
while (my($k, $v) = each %hv) {
    ++$n;
    if ($n > $kno) {
	undef $ok;
	last;
    }
}
print $ok ? "ok $t\n" : "not ok $t\n";
++$t;
$ok = 1;
$n = 0;
while (my($k, $v) = each %hv) {
    ++$n;
    if ($n > $kno) {
	undef $ok;
	last;
    }
    $check{$k} or undef $ok;
    delete $check{$k};
}    
print $ok ? "ok $t\n" : "not ok $t\n";
++$t;
$ok = !(keys %check);
print $ok ? "ok $t\n" : "not ok $t\n";

# --- EXISTS
++$t;
$hv{there} = undef;
$ok = exists $hv{there};
print $ok ? "ok $t\n" : "not ok $t\n";
++$t;
$ok = !(exists $hv{not_there});
print $ok ? "ok $t\n" : "not ok $t\n";

# --- DELETE
++$t;
$hv{there} = 'yes';
my $smoked = delete $hv{there};
$ok = !(exists $hv{there});
print $ok ? "ok $t\n" : "not ok $t\n";
++$t;
$ok = ($smoked eq 'yes');
print $ok ? "ok $t\n" : "not ok $t\n";

# --- CLEAR
++$t;
%hv = ();
$n = keys %hv;
$ok = ($n == 0);
print $ok ? "ok $t\n" : "not ok $t\n";

# --- Done!
exit;
