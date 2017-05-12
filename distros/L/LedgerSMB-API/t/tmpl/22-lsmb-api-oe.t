#!perl -T

my $parts_id = '10125';
my $customer_id = '10135';
my $email = 'tester@example.net';
use lib qw( lib );
use Test::More tests => 5;
use Test::DatabaseRow;

BEGIN {
	use_ok( 'LedgerSMB::API' );
}

my ($myconfig,$lsmb) = LedgerSMB::API->new_lsmb('LSMB_USER');
local $Test::DatabaseRow::dbh = $lsmb->{'dbh'};

isa_ok($lsmb,'Form');
isa_ok($lsmb->{'dbh'},'DBI::db');

my $date;
{
  $ENV{PATH} = '/bin/';
  $date = `date +'%Y-%m-%d'`;
  chomp($date);
  # print $date,"\n";
}

%fields = (
      customer_id => $customer_id,
         customer => 'The Testing Group--10131',
         rowcount => 2,
         assembly => 1,
            title => 'Add+Sales+Order',
             type => 'sales_order',
         formname => 'sales_order',
            media => 'screen',
           format => 'html',
         currency => 'USD', 
  defaultcurrency => 'USD',
   selectcurrency => 'USD',
            forex => 0,
        transdate => $date,
      taxaccounts => '',
    # taxaccounts => 2150,
  runningnumber_1 => 1,
     partnumber_1 => 'Assy-1000',
    description_1 => 'Widgets, 1000 for the voracious user',
             id_1 => '10125',
            qty_1 => 1,
         weight_1 => 0,
      listprice_1 => '250.00',
       lastcost_1 => '98.00',
    taxaccounts_1 => '',
  # taxaccounts_1 => '2150',
    pricematrix_1 => '0:0',
            sku_1 => 'Assy-1000',
           unit_1 => 'each',
      sellprice_1 => '149.95',
income_accno_id_1 => '10049'
          );

my $order_id = LedgerSMB::API->create_new_sales_order($myconfig,$lsmb,\%fields);
# print STDERR "The result is order no.: $order_id \n";

row_ok( table => 'oe',
        where => [ customer_id => $customer_id,
                     ordnumber => $order_id ] ,
        tests => { 'eq' => { amount => '149.95', 
                          transdate => $date }
           },
        label => "order no. $order_id successfully inserted into LSMB application, oe table has correct amount and date for this order and customer."
    );

row_ok(   sql => "SELECT * FROM orderitems oi LEFT JOIN oe ON oi.trans_id = oe.id WHERE parts_id = $parts_id AND oe.ordnumber = $order_id",
      # table => 'orderitems',
      # where => [ parts_id => $parts_id ] ,
        tests => { 'eq' => { sellprice => '149.95' }
           },
        label => "order no. $order_id successfully inserted into LSMB application, orderitems returns correct sellprice for order and part ids."
    );

# diag( "Testing LedgerSMB::API $LedgerSMB::API::VERSION, Perl $], $^X" );
