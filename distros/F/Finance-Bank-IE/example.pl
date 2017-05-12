#!perl
#
# Finance::Bank::IE example code
#
use lib qw( ./lib );
use strict;
use warnings;

use Finance::Bank::IE;
use POSIX;
use Getopt::Long;

my %config = (
              "user" => "",
              "pin" => "",
              "contact" => "",
              "dob" => "",
             );

my ( $from, $to, $amount, $detail );

GetOptions( "from=s" => \$from,
            "to=s" => \$to,
            "amount=s" => \$amount,
            "detail=s" => \$detail ) or die "bad args";

my @accounts = Finance::Bank::IE::BankOfIreland->check_balance( \%config );

foreach ( @accounts ) {
    printf "%8s : %s %8.2f\n",
      $_->{account_no}, $_->{currency}, $_->{balance};
}

print "=" x 79 . "\n";

my ( $source, $dest );
if (( $from||"" ) and ( $to||"" ) and ( $amount ||"" )) {
    for my $account ( @accounts ) {
        if ( $account->{account_no} eq $from or $account->{nick} eq $from ) {
            $source = $account;
        }
        if ( $account->{account_no} eq $to or $account->{nick} eq $to ) {
            $dest = $account;
        }
    }

    if ( !defined( $source )) {
        die "$from isn't a valid source account\n";
    }
    if ( !defined( $dest ) and $to !~ /^[0-9]{8}$/ ) {
        die "$to isn't a valid destination account\n";
    }

    Finance::Bank::IE::BankOfIreland->funds_transfer( $source->{nick}, $to, $amount );
}

$| = 1;
if ( @accounts and defined( $detail )) {
    print "Detail: $detail\n";
    for my $account ( @accounts ) {
        if ( $account->{account_no} eq $detail or
             $account->{nick} eq $detail ) {
            $source = $account;
        }
    }
    if ( !defined( $source )) {
        $source = $accounts[-1];
    }
    print "Getting account details for " . $source->{nick} . "...";
    my @activity = Finance::Bank::IE::BankOfIreland->account_details( $source->{account_no} );
    print "done\n";

    my $date;
    for my $line ( @activity ) {
        my @cols = @$line;
        my $date = shift @cols;
        if ( $date =~ /^\d+$/ ) {
            print strftime( "%Y%m%d\t", localtime( $date ));
        } else {
            print $date . "\t";
        }
        for my $col ( 0..$#cols ) {
            printf( "[%s]", $cols[$col]);
        }
        print "\n";
    }
}
