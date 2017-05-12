# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
use strict;

use vars qw($Total_tests);

my $loaded;
my $test_num = 1;
BEGIN { $| = 1; $^W = 1; }
END {print "not ok $test_num\n" unless $loaded;}
print "1..$Total_tests\n";
use Geo::Walkabout::Chain;
$loaded = 1;
ok(1, 'compile');
######################### End of black magic.

# Utility testing functions.
sub ok {
    my($test, $name) = @_;
    print "not " unless $test;
    print "ok $test_num";
    print " - $name" if defined $name;
    print "\n";
    $test_num++;
}

sub eqarray  {
    my($a1, $a2) = @_;
    return 0 unless @$a1 == @$a2;
    my $ok = 1;
    for (0..$#{$a1}) {
        my($e1,$e2) = ($a1->[$_], $a2->[$_]);
        unless($e1 eq $e2) {
            if( UNIVERSAL::isa($e1, 'ARRAY') and 
                UNIVERSAL::isa($e2, 'ARRAY') ) 
            {
                $ok = eqarray($e1, $e2);
            }
            else {
                $ok = 0;
            }
            last unless $ok;
        }
    }
    return $ok;
}

# Change this to your # of ok() calls + 1
BEGIN { $Total_tests = 1 + 5 * 2 + 5 }

my $orig_pgpath = '[(1,1), (-22,2), (3.4,3)]';

my $chain1 = Geo::Walkabout::Chain->new([1,1],[-22,2],[3.4,3]);
my $chain2 = Geo::Walkabout::Chain->new_from_pgpath($orig_pgpath);

my @chains = ($chain1, $chain2);

foreach my $chain (@chains) {
    ok( defined $chain and $chain->isa('Geo::Walkabout::Chain') );
    ok( eqarray($chain->begin, [1,1])   );
    ok( eqarray($chain->end,   [3.4,3]) );
    ok( eqarray($chain->shape, [-22,2]) );
    ok( eqarray([$chain->begin, $chain->shape, $chain->end],
                [$chain->chain]) );
}

ok($chain1->as_pgpath eq $orig_pgpath);

my $begin = $chain1->begin;
my @shape = $chain1->shape;
my $end   = $chain1->end;
$chain1->append_shape([5,5], [6,6]);
ok( eqarray([$chain1->shape], [@shape, [5,5], [6,6]]) );
ok( eqarray($chain1->begin, $begin) );
ok( eqarray($chain1->end,   $end)   );

ok( Geo::Walkabout::Chain->to_pgpoint([-2,4.5]) eq '(-2, 4.5)' );
