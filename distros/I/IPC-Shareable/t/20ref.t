BEGIN {
    $^W = 1;
    $| = 1;
    $SIG{INT} = sub { die };
    print "1..8\n";
}

use strict;
use Carp;
use IPC::Shareable;
my $t  = 1;
my $ok = 1;
my $sv;

# --- Scalar refs
tie($sv, 'IPC::Shareable', { destroy => 'yes' })
    or croak "Could not tie scalar";
my $ref = 'ref';
$sv = \$ref;
$$sv eq 'ref' or undef $ok;
print $ok ? "ok $t\n" : "not ok $t\n";

# --- Array refs
++$t;
$ok = 1;
$sv = [ 0 .. 9 ];
for (0 .. 9) {
    ($sv->[$_] eq $_) or undef $ok;
}
print $ok ? "ok $t\n" : "not ok $t\n";

# --- Hash refs
my %check;
++$t;
$ok = 1;
my @k = map { ('a' .. 'z')[int(rand(26))] } (0 .. 9);
my @v = map { ('A' .. 'Z')[int(rand(26))] } (0 .. 9);
@check{@k} = @v;
$sv = { %check };
while (my($k, $v) = each %check){
    $sv->{$k} eq $v or undef $ok;
}
print $ok ? "ok $t\n" : "not ok $t\n";

# --- Multiple refs
my @av;
tie @av => 'IPC::Shareable';
$av[0] = { foo => 'bar', baz => 'bash' };
$av[1] = [ 0 .. 9 ];

++$t;
$ok = ($av[0]->{foo} eq 'bar');
print $ok ? "ok $t\n" : "not ok $t\n";

++$t;
$ok = ($av[0]->{baz} eq 'bash');
print $ok ? "ok $t\n" : "not ok $t\n";

++$t;
$ok = 1;
for (0 .. 9) {
    $av[1]->[$_] == $_ or undef $ok;
}
print $ok ? "ok $t\n" : "not ok $t\n";

my %hv;
tie %hv => 'IPC::Shareable';
for ('a' .. 'z') {
    $hv{lower}->{$_} = $_;
    $hv{upper}->{$_} = uc;
}

++$t;
$ok = 1;
for ('a' .. 'z') {
    $hv{lower}->{$_} eq $_ or undef $ok;
    $hv{upper}->{$_} eq uc or undef $ok;
}
print $ok ? "ok $t\n" : "not ok $t\n";

IPC::Shareable->clean_up_all;
tie($sv, 'IPC::Shareable', { destroy => 'yes' })
    or croak "Could not tie scalar";

# --- Deeply nested thingies
++$t;
$sv->{this}->{is}->{nested}->{deeply}->[0]->[1]->[2] = 'found';
$ok = ($sv->{this}->{is}->{nested}->{deeply}->[0]->[1]->[2] eq 'found');
print $ok ? "ok $t\n" : "not ok $t\n";

IPC::Shareable->clean_up_all;

# --- Done!
exit;
