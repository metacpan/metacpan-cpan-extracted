#! /usr/bin/perl
#---------------------------------------------------------------------
# Example usage of Finance::PaycheckRecords
# by Christopher J. Madsen
#
# This example script is in the public domain.
# Copy from it as you like.
#---------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

use autodie ':io';

use Finance::PaycheckRecords;

my $fn = shift // die;

my $paystub = parse_paystub(file => $fn);

#use Data::Dumper;      say Dumper $paystub; exit;
#use Data::Dump qw(dump); say dump $paystub; exit;
#use YAML::Tiny qw(Dump); say Dump $paystub; exit;

$fn =~ s!\.html$!.qif! or die "Expected .html extension";

open(my $out, '>:utf8', $fn);

print $out <<'END QIF HEADER';
!Account
NAssets:MyBank
TBank
^
!Type:Bank
END QIF HEADER

print $out paystub_to_QIF($paystub, {
  category => 'Assets:MyBank',
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
});
