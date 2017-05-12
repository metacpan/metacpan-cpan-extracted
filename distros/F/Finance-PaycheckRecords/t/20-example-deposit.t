#! /usr/bin/perl
#---------------------------------------------------------------------
# $Id$
# Copyright 2013 Christopher J. Madsen
#
# Parse example/Paycheck-2015-10-23.html (direct deposit)
#---------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

use Test::More 0.88; # done_testing

plan tests => 5;

# Load Test::Differences, if available:
BEGIN {
  if (eval "use Test::Differences; 1") {
    # Not all versions of Test::Differences support changing the style:
    eval { Test::Differences::unified_diff() }
  } else {
    eval '*eq_or_diff = \&is;'; # Just use "is" instead
  }
} # end BEGIN

use Finance::PaycheckRecords;

#---------------------------------------------------------------------
# Parsing tests

my $filename = 'example/Paycheck-2015-10-23.html';
my $expected_paystub = {
  company      => "Small Employer LLC\n456 Main St, Suite 123\nSmalltown, ST 12345",
  date         => "10/23/2015",
  pay_period   => "10/03/2015 - 10/16/2015",
  payee        => "Jane Q Public\n1234 Residential Rd.\nApt. 123\nSmalltown, \nST\n12345", # FIXME only <br> should create newlines
  split        => {
    'PAY' => {
      Salary => { Current => '3333.33', Hours => '', Rate => '',
                  YTD     => '73333.26' },
      Reimbursement => { Current =>   '0.00', Hours => '', Rate => '',
                         YTD     => '555.55' },
      'On-Call Bonus' => { Current =>  '222.22', Hours => '', Rate => '',
                           YTD     => '4888.84' },
    },
    'TAXES WITHHELD' => {
      'Federal Income Tax' => { Current => '879.70', YTD => '19353.40' },
      'Medicare'           => { Current =>  '85.98', YTD =>  '1891.56' },
      'Social Security'    => { Current => '367.65', YTD =>  '8088.30' },
    },
    'SUMMARY' => {
      'Deductions' => { Current =>    '0.00', YTD =>     '0.00' },
      'Taxes'      => { Current => '1333.33', YTD => '29333.26' },
      'Total Pay'  => { Current => '3555.55', YTD => '78222.10' },
    },
  },
  totals       => {
    "Net This Check" => '2222.22',
    "Acct#....1234"  => '2222.22',
  },
};

is_deeply(parse_paystub(file => $filename),
          $expected_paystub,
          "parse from filename");

if (open(my $filehandle, '<', $filename)) {
  is_deeply(parse_paystub(file => $filename),
            $expected_paystub,
            "parse from filehandle");
  if (seek $filehandle, 0, 0) {
    my $string = do { local $/; <$filehandle> };
    is_deeply(parse_paystub(string => $string),
              $expected_paystub,
              "parse from string");
  } else {
    ok(0, "Failed to seek $filename: $!"); # parse from string
  }
} else {
  ok(0, "Failed to open $filename: $!"); # parse from filehandle
  ok(0, "Failed to open $filename: $!"); # parse from string
}

#---------------------------------------------------------------------
# QIF generation tests:

eq_or_diff(paystub_to_QIF($expected_paystub, {
     category => 'Assets:MyBank',
     memo     => 'My paycheck',
     income => {
       PAY => {
         Salary => [ 'Income:Salary' ],
         'On-Call Bonus' => [ 'Income:On-Call Bonus' ],
       },
     },
     expenses => {
       'TAXES WITHHELD' => {
         'Federal Income Tax' => [ 'Expenses:Tax:Fed', 'Federal income tax' ],
         'Medicare'        => [ 'Expenses:Tax:Medicare', 'Medicare tax' ],
         'Social Security' => [ 'Expenses:Tax:Soc Sec', 'Social Security tax' ],
       },
     },
   }),
   <<'', 'generate QIF');
D10/23/2015
PSmall Employer LLC
A456 Main St, Suite 123
ASmalltown, ST 12345
MMy paycheck
T2222.22
LAssets:MyBank
SIncome:On-Call Bonus
$222.22
SIncome:Salary
$3333.33
SExpenses:Tax:Fed
EFederal income tax
$-879.70
SExpenses:Tax:Medicare
EMedicare tax
$-85.98
SExpenses:Tax:Soc Sec
ESocial Security tax
$-367.65
^

eq_or_diff(paystub_to_QIF($expected_paystub, {
     category => 'Assets:MyBank',
     income => {
       PAY => {
         Salary => [ 'Income:Salary' ],
         'On-Call Bonus' => [ 'Income:On-Call Bonus' ],
       },
     },
     expenses => {
       'TAXES WITHHELD' => {
         'Federal Income Tax' => [ 'Expenses:Tax', 'Federal income tax' ],
         'Medicare'        => [ 'Expenses:Tax', 'Medicare tax' ],
         'Social Security' => [ 'Expenses:Tax', 'Social Security tax' ],
       },
     },
   }),
   <<'', 'sorting splits in QIF');
D10/23/2015
PSmall Employer LLC
A456 Main St, Suite 123
ASmalltown, ST 12345
MPaycheck for 10/03/2015 - 10/16/2015
T2222.22
LAssets:MyBank
SIncome:On-Call Bonus
$222.22
SIncome:Salary
$3333.33
SExpenses:Tax
EFederal income tax
$-879.70
SExpenses:Tax
ESocial Security tax
$-367.65
SExpenses:Tax
EMedicare tax
$-85.98
^

#---------------------------------------------------------------------
done_testing;
