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
use Geo::Walkabout::Line;
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
BEGIN { $Total_tests = 13 }

require Geo::Walkabout::Chain;

my $chain = Geo::Walkabout::Chain->new([1,1], [2,2], [3,3], [4,4]);

my %line_data = (
                 TLID       => 42,

                 FeDirP     => 'N',
                 FeName     => 'Yarrow',
                 FeType     => 'Way',
                 FeDirS     => 'EX',

                 ZipR       => 11731,
                 ZipL       => 11732,

                 Chain      => $chain
                );

my $line  = Geo::Walkabout::Line->new(\%line_data);

ok( defined $line && $line->isa('Geo::Walkabout::Line') );

ok( $line->TLID == 42 );
ok( $line->id   == 42 );
ok( eqarray [11732, 11731], [$line->zip] );
ok( $line->chain == $chain );

ok( $line->FeDirP eq 'N' );
ok( $line->FeName eq 'Yarrow' );
ok( $line->FeType eq 'Way' );
ok( $line->FeDirS eq 'EX' );

my %addresses = (
                 right => [[290,200], [146,146], [20,10]],
                 left  => [[291,201]]
                );
$line->add_addresses('R', @{$addresses{right}} );
$line->add_addresses('L', @{$addresses{left}}  );

ok( eqarray [sort { "@$a" cmp "@$b" } $line->addresses_left],  
            [sort { "@$a" cmp "@$b" } @{$addresses{left}}]  );
ok( eqarray [sort { "@$a" cmp "@$b" } $line->addresses_right], 
            [sort { "@$a" cmp "@$b" } @{$addresses{right}}] );

$line->chain->append_shape([23,23]);
$line->commit;

my $line_check = Geo::Walkabout::Line->retrieve($line->id);
ok( eqarray( [$line_check->chain->shape], [$line->chain->shape] ) );

$line->db_Main->rollback;
