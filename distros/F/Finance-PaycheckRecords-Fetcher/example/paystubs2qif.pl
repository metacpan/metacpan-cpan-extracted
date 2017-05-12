#! /usr/bin/env perl
#---------------------------------------------------------------------
# Fetch & process paystubs from PaycheckRecords.com
#
# This example script is in the public domain.
#
# You'll need to insert your username/password, and adjust the QIF
# category mapping. (Search for UPDATE.)
#---------------------------------------------------------------------

use strict;
use warnings;
use 5.010;

use autodie ':io';

use Finance::PaycheckRecords;
use Getopt::Long 2.17;

our $VERSION = '1.000';

my ($fetch_paystubs, $payday_only, $quiet);

Getopt::Long::config(qw(bundling no_getopt_compat));
GetOptions(
    'fetch|f'         => \$fetch_paystubs,
    'payday-only|p'   => \$payday_only,
    'quiet|q'         => \$quiet,
    'help'            => \&usage,
    'version'         => \&usage
) or usage();

sub usage {
    print "$0 $VERSION\n";
    exit if $_[0] and $_[0] eq 'version';
    print "\n" . <<'';
Usage:  $0 [options] [file ...]
  -f, --fetch           Download new paystubs
  -p, --payday-only     Run only if this is payday
  -q, --quiet           Don't output anything except errors
      --help            Display this help message
      --version         Display version information

    exit;
} # end usage

#---------------------------------------------------------------------
if ($fetch_paystubs) {
  require Finance::PaycheckRecords::Fetcher;

  # With my company, paystubs are usually available a few days before
  # payday.  But it varies a bit.  When running from crontab, I don't
  # want to fetch when there's no possibility of a paystub.  Since I
  # get paid every 2 weeks, I start looking 11 days after the last
  # paycheck date.
  if ($payday_only) {
    require DateTime;

    my $min = DateTime->now(time_zone => 'local')
                      ->subtract(days => 11) # start tryping after 11 days
                      ->format_cldr("'Paycheck-'yyyy-MM-dd'.html'");

    my @existing = sort glob 'Paycheck-*.html';

    exit if @existing and $existing[-1] gt $min;
  }

  my $f = Finance::PaycheckRecords::Fetcher->new(
    qw( your_username_here your_password_here ) # UPDATE THESE!!!
  );

  push @ARGV, $f->mirror;
}

#---------------------------------------------------------------------
# Parse paystubs in @ARGV and create QIF file

exit unless @ARGV;

# UPDATE Assets:Checking to match your account name
my $qif = <<'END QIF HEADER';
!Account
NAssets:Checking
TBank
^
!Type:Bank
END QIF HEADER

for my $fn (@ARGV) {
  my $paystub = parse_paystub(file => $fn);

  #use YAML::XS qw(Dump); say Dump $paystub;

  my $memo = "Paycheck for $paystub->{pay_period}";
  $memo =~ s!/\d{4}!!g;         # Remove years
  $memo =~ s!(^| )0!$1!g;       # Remove leading zeros

  $memo .= ' + expenses'
      if $paystub->{split}{PAY}{Reimbursement}
      and ($paystub->{split}{PAY}{Reimbursement}{Current} || 0) > 0;

  # Don't want the address, just the company name
  $paystub->{company} =~ s/\s*\n.*//s;

  # UPDATE this mapping based on your paystub & income/expense categories
  $qif .= paystub_to_QIF($paystub, {
    category => 'Assets:Checking',
    memo     => $memo,
    income => {
      PAY => {
        Salary => [ 'Income:Salary', '' ],
        Bonus => [ 'Income:Bonus', '' ],
        Reimbursement => [ 'Expenses:Business',
                           'Reimbursement for business expenses' ],
      },
    },
    expenses => {
      'TAXES WITHHELD' => {
        'Federal Income Tax' => [ 'Expenses:Tax:Fed', 'Federal Income Tax' ],
        Medicare => [ 'Expenses:Tax:Medicare', 'Medicare' ],
        'Social Security' => [ 'Expenses:Tax:Soc Sec', 'Social Security' ],
      },
    },
  });
}

my $fn = $ARGV[0];
$fn =~ s!\.html$!.qif! or die;

# If we're processing multiple paychecks,
# then name the file with the minimum & maximum dates.
if (@ARGV > 1) {
  my @dates = sort map { /Paycheck-([-0-9]+)/ or die $_; $1 } @ARGV;
  $fn = "Paychecks-$dates[0]--$dates[-1].qif";
}

say "Writing $fn ..." unless $quiet;
open(my $out, '>:utf8', $fn);
print $out $qif;
close $out;
