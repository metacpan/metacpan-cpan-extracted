use Hash::SafeKeys;
use Test::More tests => 25;
use strict;
use warnings;


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

# do builtins reset the iterator?
my ($k1,$v1) = each %hash;
my ($k2,$v2) = each %hash;
ok($k1 ne $k2, "each ok");
keys %hash;
my ($k3,$v3) = each %hash;
ok($k1 eq $k3 && $v1 eq $v3, "builtin keys resets iterator");
values %hash;
my ($k4,$v4) = each %hash;
ok($k1 eq $k4 && $v1 eq $v4, "builtin values resets iterator");
my %copy = %hash;
scalar each %hash;
my ($k5,$v5) = each %hash;
ok($k2 eq $k5 && $v2 eq $v5, "list eval of hash resets iterator");

# builtins in scalar context
keys %hash;
($k1,$v1) = each %hash;
($k2,$v2) = each %hash;
my $n = keys %hash;
($k3,$v3) = each %hash;
ok($k1 eq $k3 && $v1 eq $v3, 'scalar keys resets iterator');
$n = values %hash;
($k4,$v4) = each %hash;
ok($k1 eq $k4 && $v1 eq $v4, 'scalar values reset iterator');
$n = %hash;
($k5,$v5) = each %hash;
ok($k1 ne $k5, 'scalar %HASH does not reset iterator');

# is return for safekeys and safevalues same as keys and values?
my @k1 = keys %hash;
my @k2 = safekeys %hash;
ok( @k1 > 0 && @k1 == @k2, 'safekeys returns data' );
ok( "@k1" eq "@k2" , 'safekeys returns same order as keys' );

my $nk1 = keys %hash;
my $nk2 = safekeys %hash;
ok($nk1 == $nk2, 'scalar safekeys returns same value as keys');

my @v1 = values %hash;
my @v2 = safevalues %hash;
ok( @v1 > 0 && @v1 == @v2, 'safevalues returns data' );
ok( join(q/;/,@v1) eq join(q/;/,@v2),
    'safevalues returns same order as values' );
my $nv1 = values %hash;
my $nv2 = safevalues %hash;
ok($nv1==$nv2, 'scalar safevalues returns same value as values');

my $ns1 = %hash;
my $ns2 = safecopy %hash;
ok($ns1 eq $ns2, 'scalar safecopy returns same value as scalar HASH');

# is return for safekeys and safevalues the same inside each iterator ?
# do safekeys/safevalues protect the iterator?
keys %hash; # reset
while ( my ($k6,$v6) = each %hash ) {
    ok( $k6 eq $k1 && $v6 eq $v1, 'iterator reset before inside each test' );

    my @k3 = safekeys %hash;
    my @v3 = safevalues %hash;
    my ($k7,$v7) = each %hash;

    ok( "@k3" eq "@k1" ,
        'safekeys returns correct data, correct order after each' );
    ok( join(q/;;/,@v3) eq join(q/;;/,@v1),
	'safevalues returns correct data, correct order after each' );
    ok( $k6 ne $k7 && $v6 ne $v7,
	'each iterator was not reset after safekeys/safevalues' );
    ok( $k7 eq $k2 && $v7 eq $v2, '2nd each call returns 2nd key/val pair' );

    last;  # ok, it's not much of a while loop
}

# the infinite loop tests
my $count = 0;
my %foo = (abc => 123, def => 456);
while (each %foo) {
    last if $count++ > 100;
    keys %foo;
    values %foo;
    () = sort %foo;
}
ok($count >= 100, 'builtins inside each create infinite loop' );

keys %foo;
$count = 0;
while (each %foo) {
    last if $count++ > 100;
    safekeys %foo;
    safevalues %foo;
    my %foo2 = safecopy %foo;
}
ok($count < 3, 'safe versions do not create infinite loop' );

no warnings 'uninitialized';
keys %hash;
my @kk0 = keys %{$hash{quux}};
my $vv0 = join q/--/, values %{$hash{quux}};

# with 5.17.6, 5.18, two identical hashes can return kv's in different order
my $hh0 = join q/==/,sort %{$hash{quux}};

while (my($k,$v) = each %hash) {
    if (ref($v) eq 'HASH') {
	my $count = 0;
	my (@kk,@vv,%hh);
	while (my($kk,$vv) = each %$v) {
	    last if ++$count > 100;
	    @kk = safekeys %$v;
	    @vv = safevalues %$v;
	    %hh = safecopy %$v;
	}
	ok( $count < 10, 'second level each not an infinite loop' );
	ok( "@kk0" eq "@kk", 'second level safekeys have correct data,order' );
	ok( $vv0 eq join(q/--/,@vv),
	    'second level safevals have correct data,order' );
	ok( $hh0 eq join(q/==/,sort %hh),
	    'second level safecopy has correct data' );
    }
}
