#! /usr/bin/perl
#---------------------------------------------------------------------
# $Id$
# Copyright 2013 Christopher J. Madsen
#
# Parse example/Paycheck-2013-01-04.html
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

my $filename = 'example/Paycheck-2013-01-04.html';
my $expected_paystub = {
  check_number => 3456,
  company      => "Big Employer\n123 Any St.\nBig City, ST 12345",
  date         => "01/04/2013",
  pay_period   => "12/15/2012 - 12/28/2012",
  payee        => "John Q. Public\n789 Main St.\nApt. 234\nMy Town, ST 12567",
  split        => {
    'PAY' => {
      Salary => { Current => '1766.65', Hours => '', Rate => '',
                  YTD     => '1766.65' },
    },
    'TAXES WITHHELD' => {
      'Federal Income Tax' => { Current => '333.33', YTD => '333.33' },
      'Medicare'           => { Current =>  '99.99', YTD =>  '99.99' },
      'Social Security'    => { Current => '222.22', YTD => '222.22' },
    },
    'SUMMARY' => {
      'Deductions' => { Current =>    '0.00', YTD =>    '0.00' },
      'Taxes'      => { Current =>  '655.54', YTD =>  '655.54' },
      'Total Pay'  => { Current => '1766.65', YTD => '1766.65' },
    },
  },
  totals       => { "Net This Check" => '1111.11' },
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

is(paystub_to_QIF($expected_paystub, {
     category => 'Assets:MyBank',
     memo     => 'My paycheck',
     income => {
       PAY => {
         Salary => [ 'Income:Salary' ],
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
D01/04/2013
N3456
PBig Employer
A123 Any St.
ABig City, ST 12345
MMy paycheck
T1111.11
LAssets:MyBank
SIncome:Salary
$1766.65
SExpenses:Tax:Fed
EFederal income tax
$-333.33
SExpenses:Tax:Medicare
EMedicare tax
$-99.99
SExpenses:Tax:Soc Sec
ESocial Security tax
$-222.22
^

is(paystub_to_QIF($expected_paystub, {
     category => 'Assets:MyBank',
     income => {
       PAY => {
         Salary => [ 'Income:Salary' ],
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
D01/04/2013
N3456
PBig Employer
A123 Any St.
ABig City, ST 12345
MPaycheck for 12/15/2012 - 12/28/2012
T1111.11
LAssets:MyBank
SIncome:Salary
$1766.65
SExpenses:Tax
EFederal income tax
$-333.33
SExpenses:Tax
ESocial Security tax
$-222.22
SExpenses:Tax
EMedicare tax
$-99.99
^

#---------------------------------------------------------------------
done_testing;
