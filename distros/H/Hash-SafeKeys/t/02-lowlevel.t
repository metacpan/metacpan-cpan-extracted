use Hash::SafeKeys ':all';
use Test::More tests => 18;
use strict;
use warnings;

# exercise the low-level iterator functions  save_iterator_state  and
# restore_iterator_state

my %hash = (
    foo => 123,
    bar => "456",
    baz => [ 3, 17, "Alpha", { "Bravo" => "Charlie", "Delta" => "Echo" },
	     [ "Foxtrot", "Golf", "Hotel" ], *STDERR,
	     sub { my($i,$j,$k) = @_; return 42*$i+$j/$k; } ],
    quux => { "Lima" => "Mike",
	      "November" => *Oscar,
	      "Papa" => sub { "Quebec" },
	      "Romeo" => [ qw(Sierra Tango Uniform) ],
	      "Victor" => { "Whiskey" => { "X-ray" => "Yankee" } },
	      "Zulu" => undef }
    );
close *Oscar if 0; # suppress "used only once" warning

#############################################################################

my @k1 = keys %hash;
my @v1 = values %hash;
my @k2 = safekeys %hash;
my @v2 = safevalues %hash;

my $it = save_iterator_state(\%hash);
my @k3 = keys %hash;
my @v3 = values %hash;
restore_iterator_state(\%hash, $it);

ok("@k1" eq "@k3", 'keys from new iterator match keys');
ok("@k2" eq "@k3", 'keys from new iterator match safekeys');

ok("@v1" eq "@v3", 'keys from new iterator match values');
ok("@v2" eq "@v3", 'keys from new iterator match safevalues');


my @it = map { save_iterator_state(\%hash) } 0 .. 100;
ok(1, 'multiple calls to save_iterator_state does not crash');
my $z = 0;
$z += restore_iterator_state(\%hash, $_) for reverse @it;
ok($z == @it, 'all restore calls successful');
ok(!restore_iterator_state(\%hash, $it[20]),
   'extraneous restore_iterator_state is returns false');



# save way to call keys inside each

my $c = 0;
my %foo = (abc => 123, def => 456);
while (each %foo) {
    last if $c++ > 100;
    keys %foo;
}
ok($c >= 100, 'builtin keys inside each makes infinite loop');

keys %foo;
$c = 0;
while (each %foo) {
    last if $c++ > 100;
    my $it = save_iterator_state(\%foo);
    keys %foo;
    restore_iterator_state(\%foo,$it);    
}
ok($c < 100, 'builtin keys with iterator_state guard safe inside each');



# safely modify values
my %bar = ('aa' .. 'zz');
$c = 0;
while (each %bar) {
    foreach (values %bar) {
        s/ez/EZ/g;
    }
    last if $c++ > 1000;
}
ok($c >= 1000, 'builtin values inside each makes infinite loop');
ok($bar{"ey"} eq 'EZ', 'values modified');

$c = 0;
keys %bar;
while (each %bar) {
    foreach (safevalues %bar) {
        s/in/IN/;
    }
    last if $c++ > 1000;
}
ok($c < 1000, 'safevalues inside each is safe');
ok($bar{"im"} eq "in" && $bar{"im"} ne "IN", 'safevalues not modified');

keys %bar;
$c = 0;
while (each %bar) {
    my $it = save_iterator_state(\%bar);
    foreach (values %bar) {
        s/xz/XZ/;
    }
    restore_iterator_state(\%bar,$it);
    last if $c++ > 1000;
}
ok($c < 1000, 'values inside each is safe with iterator_state guard');
ok($bar{"xy"} eq 'XZ', 'values modified');



# nested each
my $hash2 = { 1 .. 10 };
my $hash3 = { 1 .. 10 };
my $count = 0;
my %r;
EACH1: while (my ($k2,$v2) = each %$hash2) {
    while (my ($k3,$v3) = each %$hash3) {
        $count++;
        last EACH1 if $count > 100;
        $r{"$k2:$k3"}++;
    }
}
ok($count < 100, 'nested each ok for different hash');
keys %$hash2;

$count = 0;
my $hash4 = $hash2;
EACH2: while (my ($k2,$v2) = each %$hash2) {
    while (my ($k4,$v4) = each %$hash4) {
        $count++;
        last EACH2 if $count > 100;
        $r{"$k2:$k4"}++;
    }
}
ok($count >= 100, 'nested each not ok for same hash');
keys %$hash2;

$count = 0;
EACH3: while (my ($k2,$v2) = each %$hash2) {
    my $it = Hash::SafeKeys::save_iterator_state($hash4);
    while (my ($k4,$v4) = each %$hash4) {
        $count++;
        last EACH3 if $count > 100;
        $r{"$k2:$k4"}++;
    }
    Hash::SafeKeys::restore_iterator_state($hash4, $it);
}
ok($count < 100, 'safe nested hash ok for same hash');
keys %$hash2;

        

