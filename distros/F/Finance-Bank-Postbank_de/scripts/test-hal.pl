#!perl -w
package main;
use strict;
use WWW::Mechanize;
use LWP::Protocol::https;
use JSON 'decode_json';
#use LWP::ConsoleLogger::Easy qw( debug_ua );
use HTTP::CookieJar::LWP;
use Data::Dumper;
use Finance::Bank::Postbank_de::APIv1;

use Getopt::Long;
use Pod::Usage;

GetOptions(
    'username=s' => \my $username,
    'password=s' => \my $password,
) or pod2usage(2);

#my $logger = debug_ua($ua);
#$logger->dump_content(0);
#$logger->dump_text(0);

$username ||= 'Petra.Pfiffig';
$password ||= '12345678';

my $api = Finance::Bank::Postbank_de::APIv1->new();
$api->configure_ua();

my $postbank = $api->login( $username, $password );

my $finanzstatus = $postbank->navigate(
    class => 'Finance::Bank::Postbank_de::APIv1::Finanzstatus',
    path => ['banking_v1' => 'financialstatus']
);

my $messages = $finanzstatus->fetch_resource( 'messagebox' ); # messagebox->count
warn $_->notificationId, $_->subject for $finanzstatus->available_messages;
#warn Dumper $messages;
#warn Dumper $messages->{_embedded}->{notificationDTOList};

# if( exists $finanzstatus->{splash_page} ) {
#     show / retrieve splash page text
# }

for my $account ($finanzstatus->get_accountsPrivate ) {

    print $account->name || '',"\n";
    print $account->accountHolder || '',"\n";
    print $account->iban || '',"\n";
    print $account->amount, " ", $account->currency,"\n";

    if( $account->is_depot ) {
        my $depot = $account->fetch_resource('depot', class => 'Finance::Bank::Postbank_de::APIv1::Depot');

        print join " ", $depot->date, $depot->depotValue, $depot->depotCurrency;
        print "\n";
        for my $pos ($depot->positions) {
            print join "\t", $pos->amount, $pos->isin, $pos->averageQuote, $pos->depotCurrQuote, $pos->quoteCurrency,
                            $pos->depotCurrValue, $pos->winOrLoss, $pos->winOrLossCurrency,
                            ;
            print "\n";
        };

        next;
    };

    print Dumper $_ for $account->transactions_csv;

    print Dumper $account->_links;
};

