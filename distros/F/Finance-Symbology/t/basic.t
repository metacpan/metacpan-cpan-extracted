#!/usr/bin/perl 

use strict;
use warnings;

use lib '../lib';


chdir 't';

use Test::Simple tests => 25;
use Finance::Symbology;

ok( my $converter = Finance::Symbology->new(), 'Initialized Converter object ok' );

#testing CMS
my $whatis = $converter->what('AAPL PR');
ok( defined $whatis->{CMS} , 'This is CMS Convention' );
ok( $whatis->{CMS}{type} eq 'Preferred' , 'This is a preferred symbol' );

#testing CQS
$whatis = $converter->what('AAPLw');
ok( defined $whatis->{CQS} , 'This is CQS Convention' );
ok( $whatis->{CQS}{type} eq 'When Issued' , 'This is a when issued' );

#testing Fidessa
$whatis = $converter->what('AAPL-');
ok( defined $whatis->{FIDESSA} , 'This is a Fidessa Convention' );
ok( $whatis->{FIDESSA}{type} eq 'Preferred' , 'This is a preferred symbol' );

#testing NASDAQ Integrated
$whatis = $converter->what('AAPL-$');
ok( defined $whatis->{NASINTEGRATED} , 'This is a NASDAQ Integrated Convention' );
ok( $whatis->{NASINTEGRATED}{type} eq 'Preferred when distributed' , 'This is a preferred when distributed symbol' );

#Test converting

# testing CMS
my $convert = $converter->convert('AAPL PRCL', 'CMS', 'NASINTEGRATED');
ok( $convert eq 'AAPL-*' , 'Success: CMS -> NASDAQ Integrated' );

$convert = $converter->convert('AAPL PRCL', 'CMS', 'CQS'); 
ok( $convert eq 'AAPLp/CL' , 'Success: CMS -> CQS' );

$convert = $converter->convert('AAPL PRCL', 'CMS', 'Fidessa');
ok( $convert eq 'AAPL-CL' , 'Success: CMS -> Fidessa' );

# testing CQS
$convert = $converter->convert('AAPLp/CL', 'CQS', 'NASINTEGRATED');
ok( $convert eq 'AAPL-*' , 'Success: CQS -> NASDAQ Integrated' );

$convert = $converter->convert('AAPLp/CL', 'CQS', 'CMS'); 
ok( $convert eq 'AAPL PRCL' , 'Success: CQS -> CMS' );

$convert = $converter->convert('AAPLp/CL', 'CQS', 'Fidessa');
ok( $convert eq 'AAPL-CL' , 'Success: CQS -> Fidessa' );

#testing NASDAQ Integrated
$convert = $converter->convert('AAPL-$', 'NASINTEGRATED', 'CMS');
ok( $convert eq 'AAPL PRWD' , 'Success: NASDAQ Integrated -> CMS' );

$convert = $converter->convert('AAPL-$', 'NASINTEGRATED', 'CQS');
ok( $convert eq 'AAPLp/WD' , 'Success: NASDAQ Integrated -> CQS' );

$convert = $converter->convert('AAPL-$', 'NASINTEGRATED', 'Fidessa');
ok( $convert eq 'AAPL-WD' , 'Success: NASDAQ Integrated -> Fidessa' );

# testing Fidessa 
$convert = $converter->convert('AAPL-CL', 'FIDESSA', 'NASINTEGRATED');
ok( $convert eq 'AAPL-*' , 'Success: Fidessa -> NASDAQ Integrated' );

$convert = $converter->convert('AAPL-CL', 'Fidessa', 'CMS'); 
ok( $convert eq 'AAPL PRCL' , 'Success: Fidessa -> CMS' );

$convert = $converter->convert('AAPL-CL', 'Fidessa', 'CQS');
ok( $convert eq 'AAPLp/CL' , 'Success: Fidessa -> CQS' );

# testing list symbol conversions
my @converted = qw/AAPLp CpA GOOGpAw SPYw/;

my @results = $converter->convert(\@converted,'CQS', 'CMS');
ok ($results[0] eq 'AAPL PR', 'List 1: Conversion ok!');
ok ($results[1] eq 'C PRA', 'List 2: Conversion ok!');
ok ($results[2] eq 'GOOG PRAWI', 'List 3: Conversion ok!');
ok ($results[3] eq 'SPY WI', 'List 4: Conversion ok!');




