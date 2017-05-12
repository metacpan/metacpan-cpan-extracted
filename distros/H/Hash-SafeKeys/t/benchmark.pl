use Benchmark ':all';
use lib 'blib/lib', 'blib/arch';
use Hash::SafeKeys;
use Hash::StoredIterator qw(hash_get_iterator hash_set_iterator hkeys);
use Time::HiRes;
use strict;
use warnings;


# http://stackoverflow.com/questions/10921221/
#    can-i-copy-a-hash-without-resetting-its-each-iterator
#    ?noredirect=1#comment63376080_10921221
# proposes Hash::StoredIterator as faster than Hash::SafeKeys
#
# and how does Hash::SafeKeys perform with large hashes ?


my $t0 = Time::HiRes::time;
my %hash = (
    "aaaaa" .. "aczzz",
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
my $t1 = Time::HiRes::time;

print "Size of test hash is ", scalar keys %hash, "\n";
printf "Setup time was %.3fs\n", $t1-$t0;

my $rlist = timethese(1000, {
    builtin => sub {
        my @x = keys %hash;
    },
    safekeys => sub { 
        my @x = safekeys %hash;
    },
    storediter1 => sub {
        my $hi = hash_get_iterator(\%hash);
        my @x = keys %hash;
        hash_set_iterator(\%hash,$hi);
    },
    storediter2 => sub {
        my @x = hkeys %hash;
    },
    saverestore => sub {
        my $hi = Hash::SafeKeys::save_iterator_state(\%hash);
        my @x = keys %hash;
        Hash::SafeKeys::restore_iterator_state(\%hash, $hi);
    },
} );

# scalar context
my $rscalar = timethese(1000, {
    builtinSC => sub {
        my $x = keys %hash;
    },
    storediter1SC => sub {
        my $hi = hash_get_iterator(\%hash);
        my $x = keys %hash;
        hash_set_iterator(\%hash,$hi);
    },
    safekeysSC => sub { 
        my $x = safekeys %hash;
    },
    storediter2SC => sub { my $x = hkeys %hash },
    saverestoreSC => sub {
        my $hi = Hash::SafeKeys::save_iterator_state(\%hash);
        my $x = keys %hash;
        Hash::SafeKeys::restore_iterator_state(\%hash, $hi);
    },
                        });

cmpthese( $rscalar );
cmpthese( $rlist );

exit;

__END__

Results:

Hash::SafeKeys v0.03 - Hash::StoredIterator v0.007, 26_368 keys

SCALAR           Rate  safekeysSC  storediter2SC builtinSC storediter1SC
safekeysSC       50.9/s        --            -1%     -100%         -100%
storediter2SC    51.5/s        1%             --     -100%         -100%
builtinSC        Inf/s       Inf%           Inf%        --            0%
storediter1SC    Inf/s       Inf%           Inf%        0%            --

LIST             Rate    safekeys storediter2     builtin storediter1
safekeys       28.0/s          --         -2%        -62%        -63%
storediter2    28.5/s          2%          --        -62%        -62%
builtin        74.4/s        165%        161%          --         -1%
storediter1    75.3/s        169%        164%          1%          --


TL;DR:
     custom keys method is 3 times costlier than native
     stored iterator + native keys does not have a performance drop-off
     scalar call on custom keys method is expensive

-----

Hash::SafeKeys v0.04 - Hash::StoredIterator v0.007, 26_368 keys

SCALAR            Rate  storediter2SC safekeysSC builtinSC storediter1SC
storediter2SC   62.0/s             --      -100%     -100%         -100%
safekeysSC       Inf/s           Inf%         --        0%            0%
builtinSC        Inf/s           Inf%         0%        --            0%
storediter1SC    Inf/s           Inf%         0%        0%            --

LIST           Rate    safekeys storediter2 storediter1     builtin
safekeys     33.4/s          --         -1%        -62%        -63%
storediter2  33.7/s          1%          --        -62%        -63%
storediter1  88.0/s        164%        161%          --         -3%
builtin      90.6/s        171%        169%          3%          --

TL;DR:
     scalar custom keys call is now cheap in Hash::SafeKeys
