use strict;
use warnings;

use Benchmark qw(:all);
use Hash::BulkKeyCopy;

my $count = 1_000_000;

sub hash_bulk_keycopy($$$$) {
    my ($h1,$h2,$arr1,$arr2) = @_;
    my $a1len = scalar @$arr1;
    my $a2len = scalar @$arr2;
    return if ($a1len != $a2len || $a1len == 0);
    for (0 .. $a1len-1) {
        my $k1 = $arr1->[$_];
        my $k2 = $arr2->[$_];
        my $v = $h2->{$k2};
        $h1->{$k1} = $v if (defined $v);
    }
}

my $arr1 = [];
my $arr2 = [];
my $val2 = {};

for (0..9) {
    push @$arr1,"k1_$_";
    push @$arr2,"k2_$_";
    $val2->{"k2_$_"} = $_+1;
}

cmpthese(timethese($count, {
    'XS' => sub {
        my $h1 = {};
        my $h2 = {%$val2};
        Hash::BulkKeyCopy::hash_bulk_keycopy($h1,$h2,$arr1,$arr2);
    },
    'PP' => sub {
        my $h1 = {};
        my $h2 = {%$val2};
        hash_bulk_keycopy($h1,$h2,$arr1,$arr2);
    },
}));

__END__
$ perl -Mblib benchmark/hash_bulk_keycopy.pl 
Benchmark: timing 1000000 iterations of PP, XS...
        PP: 11 wallclock secs (10.54 usr +  0.01 sys = 10.55 CPU) @ 94786.73/s (n=1000000)
        XS:  6 wallclock secs ( 5.26 usr +  0.00 sys =  5.26 CPU) @ 190114.07/s (n=1000000)
       Rate   PP   XS
PP  94787/s   -- -50%
XS 190114/s 101%   --
