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
use Text::CSV_XS 'csv';
use Text::Table;

use Getopt::Long;
use Pod::Usage;

GetOptions(
    'username=s'      => \my $username,
    'password=s'      => \my $password,

    'csv'             => \my $output_csv,
    'xlsx'            => \my $output_xlsx,
    'xml'             => \my $output_xml,

    'o|output_file=s' => \my $output_file,
) or pod2usage(2);

#my $logger = debug_ua($ua);
#$logger->dump_content(0);
#$logger->dump_text(0);

$username ||= 'Petra.Pfiffig';
$password ||= '11111';

my $api = Finance::Bank::Postbank_de::APIv1->new();
$api->configure_ua();

my $postbank = $api->login( $username, $password );

my $finanzstatus = $postbank->navigate(
    class => 'Finance::Bank::Postbank_de::APIv1::Finanzstatus',
    path => ['banking_v1' => 'financialstatus']
);

#my $messages = $finanzstatus->fetch_resource( 'messagebox' ); # messagebox->count

my @columns = qw(isin shortDescription amount averageQuote depotCurrQuote quoteCurrency depotCurrValue winOrLoss winOrLossCurrency );
my @output;
push @output, \@columns;
my ($bp) = $finanzstatus->get_businesspartners;
for my $account ( grep { $_->is_depot } $bp->get_accounts ) {

    my $depot = $account->fetch_resource('depot', class => 'Finance::Bank::Postbank_de::APIv1::Depot');

    for my $pos ($depot->positions) {
        push @output, [ map { $pos->$_ } @columns ];
    };
};

if( $output_file ) {
    open *STDOUT, '>', $output_file;
    binmode *STDOUT;
};

if( $output_csv ) {
    csv( in => [\@columns, @output], out => \*STDOUT, sep => ';' );
} elsif( $output_xlsx ) {
    require Excel::Writer::XLSX;
    my $workbook = Excel::Writer::XLSX->new(\*STDOUT);
    my $sheet = $workbook->add_worksheet();
    $sheet->write_col( 'A1', \@output );
} else {
    my $table = Text::Table->new( @columns );
    $table->load( @output );
    print $table;
}