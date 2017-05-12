#!/usr/bin/perl
use strict;
use warnings;
use blib;  

# Testing File::RandomLine  

#--------------------------------------------------------------------------#
# Setup test  
#--------------------------------------------------------------------------#

use Test::More;
use Test::Exception;
use Test::Warn;
use File::Spec;

use Test::MockRandom 'File::RandomLine';
use File::RandomLine;

my $test_fn = 'testdata2.txt';
my $no_read_fn = 'not_readable.txt';

my (%cases, @multiples);
$cases{"0"} = "A";
$cases{"0.25"} = "Short";
$cases{"0.50"} = "Longer Line";
$cases{"0.75"} = "A Very Very Long Line";
$cases{"oneish()"} = "A Very Very Long Line";
@multiples = qw( 0.25 0 0.50 ); # must be at least three

plan tests =>  (12 + keys %cases) ;  

#--------------------------------------------------------------------------#
# Test the setup
#--------------------------------------------------------------------------#

my $test_file = -e $test_fn ? 
    $test_fn : File::Spec->catfile('t',$test_fn);
ok( -r $test_file, 
    "finding readable test data file '$test_file'" );

my $no_read_file = -e $no_read_fn ? 
    $no_read_fn : File::Spec->catfile('t',$no_read_fn);
ok( -e $no_read_file,  
    "Finding intentionally unreadable file '$no_read_file'" ); 

#--------------------------------------------------------------------------#
# Testing object construction
#--------------------------------------------------------------------------#

my $rl;

dies_ok { File::RandomLine->new($test_file, {algorithm => "test"}) }
    "dies if given an unrecognized algorithm";
ok( $rl = File::RandomLine->new($test_file, {algorithm => "uniform"}), 
    "CLASS->new works" );
isa_ok( $rl, "File::RandomLine" );

#--------------------------------------------------------------------------#
# Test usage errors
#--------------------------------------------------------------------------#

dies_ok { $rl->next(-1) } "next() croaks given negative number";
dies_ok { $rl->next('') } "next() croaks given empty string";
dies_ok { $rl->next('a') } "next() croaks given 'a'";
warning_like { $rl->next(0) } qr/strange call/i, "next() warns given 0";



#--------------------------------------------------------------------------#
# Testing getting a single random line
#--------------------------------------------------------------------------#
{

    for (sort { eval $a <=> eval $b } keys %cases) {
        srand( eval "$_" );
        is( $rl->next, $cases{$_}, "Testing with srand() = $_" );
    }

}

#--------------------------------------------------------------------------#
# Testing getting multiple random lines -- explicit
#--------------------------------------------------------------------------#
{
    srand( map { eval "$_" } @multiples );
    my $expected = [ map { $cases{$_} } @multiples ];
    my $lines = [ $rl->next(scalar @multiples) ];
    is_deeply( $lines, $expected, 
        'Testing getting multiple random lines -- explicit version');
}

#--------------------------------------------------------------------------#
# Testing getting multiple random lines -- magic
#--------------------------------------------------------------------------#
{
    srand( map { eval "$_" } @multiples[0 .. 2] );
    my $exp1 = [ map { $cases{$_} } @multiples[0 .. 1] ] ;
    my $exp2 = [ map { $cases{$_} } $multiples[2] ];

    my ($one, $two) = $rl->next();
    is_deeply( [$one, $two], $exp1, 
        'Testing getting multiple random lines -- magic version with target');

    my $result = [ $rl->next() ];
    is_deeply( $result, $exp2, 
        'Testing getting multiple random lines -- ambiguious magic version ');
    
}
