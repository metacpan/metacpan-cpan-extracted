#!/usr/bin/perl

use strict;
use warnings;

use Carp qw(carp cluck croak confess);
use Finance::Bank::LloydsTSB;
use Term::ReadLine;

sub usage {
  warn @_, "\n" if @_;

  (my $ME = $0) =~ s,.*/,,;

  die <<EOUSAGE;
Usage:
  $ME [options]                                    show account overview
  $ME [options] ACCOUNT                            dump statement for account  
  $ME [options] ACCOUNT YEAR STARTMONTH [ENDMONTH] download monthly statements

Options:
  -d, --debug
EOUSAGE
}

use Getopt::Long;

Getopt::Long::Configure('bundling');

my %opts = ( debug => 0 );
GetOptions(
  \%opts,
  'help|h',
  'debug|d',
) or usage();

usage() if $opts{help};
usage() unless @ARGV == 0 or @ARGV == 1 or (@ARGV >= 3 and @ARGV <= 4);
my ($account_name, $year, $start_month, $end_month) = @ARGV;

if ($opts{debug}) {
  $Finance::Bank::LloydsTSB::DEBUG = 1;
  $Finance::Bank::LloydsTSB::Account::DEBUG = 1;
}

my $term = new Term::ReadLine $0;
my $username  = $ENV{LTSB_USERNAME}  || $term->readline('User ID: ');
my $password  = $ENV{LTSB_PASSWD}    || read_secret('Password: ', $term);
my $memorable = $ENV{LTSB_MEMORABLE} || read_secret('Memorable info: ', $term);

my @accounts = Finance::Bank::LloydsTSB->get_accounts(
  username  => $username,
  password  => $password,
  memorable => $memorable,
);

my %accounts_by_name = map { $_->name => $_ } @accounts;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Maxdepth = 4;

my $total = 0;
my $format = "%20s : %21s : GBP %9.2f\n";
for my $acc (@accounts) {
  $total += $acc->balance;
  printf $format, $acc->name, $acc->descr_num, $acc->balance;
}
print "-" x 70, "\n";
printf $format, 'TOTAL', '', $total;

exit 0 unless $account_name;

my $account = $accounts_by_name{$account_name};
die "Couldn't find current account" unless $account;

print "Operating on $account_name\n";

if ($year) {
  download_months();
}
else {
  my $statement = $account->fetch_statement;
  print Dumper $statement;
}

sub download_months {
  for my $month ($start_month .. ($end_month || $start_month)) {
    print "Downloading $year/$month ...\n";
    my ($content_type, $qif) = $account->download_statement(
      $year, $month, 1,
      # + 1 month
      5,
    );

    my $file = sprintf "%s-%s-%02d+1.qif", $account->account_no, $year, $month;
    if ($content_type ne 'text/x-qif') {
      (my $ext = $content_type) =~ s!.*/!!;
      $file =~ s/qif$/$ext/;
    }

    open(FH, ">$file")
      or die "Couldn't open(>$file): $!\n";
    print FH $qif;
    close(FH);
    print "Wrote $file\n";
  }
}

END {
  Finance::Bank::LloydsTSB->logoff;
}

sub read_secret {
  my ($prompt, $term) = @_;
  my $attribs = $term->Attribs;
  $attribs->{redisplay_function} = $attribs->{shadow_redisplay};
  return $term->readline($prompt);
}
