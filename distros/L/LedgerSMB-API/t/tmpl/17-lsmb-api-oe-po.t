#!perl -T

my $parts_id = '10119';
my $vendor_id = '10127';
my $email = 'tester@example.net';
use lib qw( lib );
use Test::More tests => 7;
use Test::DatabaseRow;
use Data::Dumper;

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
}

# Create a Purchase Order 

%fields = (
                 title => 'Add+Purchase+Order',
                  type => 'purchase_order',
              formname => 'purchase_order',
                 media => 'screen',
                format => 'html',
                    vc => 'vendor',
       creditremaining => '',
           oldcurrency => 'USD',
           oldinvtotal => '500',
             vendor_id => $vendor_id,
             oldvendor => 'The Widget Source--10129',
              currency => 'USD', 
       defaultcurrency => 'USD',
                 forex => 0,
                vendor => 'The Widget Source--10129',
             transdate => $date,
          oldtransdate => $date,
                  path => 'bin/mozilla',
                 login => 'LSMB_USER',
              rowcount => 2,
              oldqty_1 => 5102,
                  id_1 => 10119,
           listprice_1 => 'NaN.00',
            lastcost_1 => 'NaN.00',
       # taxaccounts_1 => '2150',
                 sku_1 => 'Widget-0001',
  inventory_accno_id_1 => '10013',
     income_accno_id_1 => '10049',
    expense_accno_id_1 => '10057',
       runningnumber_1 => 1,
          partnumber_1 => 'Widget-0001',
         description_1 => 'Widget, single',
                 qty_1 => 5102,
           sellprice_1 => '0.098'
          );

my $purchase_order_id = LedgerSMB::API->create_new_purchase_order($myconfig,$lsmb,\%fields);

row_ok( table => 'oe',
        where => [   vendor_id => $vendor_id,
                     ordnumber => $purchase_order_id ] ,
        tests => { 'eq' => { amount => '500', 
                          transdate => $date }
           },
        label => "purchase order no. $purchase_order_id successfully inserted into LSMB application, oe table has correct amount and date for this order and vendor."
    );

row_ok(   sql => "SELECT * FROM orderitems oi LEFT JOIN oe ON oi.trans_id = oe.id WHERE parts_id = $parts_id AND oe.ordnumber = $purchase_order_id",
        tests => { 'eq' => { sellprice => '0.098' }
           },
        label => "purchase order no. $purchase_order_id successfully inserted into LSMB application, orderitems returns correct sellprice for order and part ids."
    );

# Post an invoice generated from a Purchase Order

my $sql = "SELECT id FROM oe WHERE ordnumber = $purchase_order_id";
my $sth = $lsmb->{'dbh'}->prepare($sql);
$sth->execute();
my ($po_transaction_id) = $sth->fetchrow_array();

$fields{'po_transaction_id'} = $po_transaction_id;
$fields{'AP'} = '2100--Accounts Payable';
my $invoice_id = LedgerSMB::API->generate_invoice_from_purchase_order($myconfig,$lsmb,\%fields);

row_ok( table => 'ap',
        where => [   vendor_id => $vendor_id,
                     invnumber => $invoice_id ] ,
        tests => { 'eq' => { amount => '500', 
                          transdate => $date,
                           ponumber => $po_transaction_id }
           },
        label => "Invoice no. $invoice_id successfully posted from PO, ap table has correct amount, date and PO number for this invoice and vendor."
    );

# Create another invoice, and post a payment to it.

$fields{'AP'} = '2100'; # --Accounts Payable';
$fields{'paidaccounts'} = '1';
$fields{'datepaid_1'} = '2009-02-05';
$fields{'source_1'} = '';
$fields{'memo_1'} = '';
$fields{'paid_1'} = '500';
$fields{'AP_paid_1'} = '2680--Loans from Shareholders';

# foreach my $trans_id ( keys %{ $form->{acc_trans} } ) {
#   foreach my $accno ( keys %{ $form->{acc_trans}{$trans_id} } ) {
#     $amount = $form->round_amount( $form->{acc_trans}{$trans_id}{$accno}{amount}, 2 );
# print STDERR $accno . ' : ' . Dumper(\$form->{'acc_trans'});

$fields{acctrans}{$po_transaction_id}{'2680'}{'amount'} = '500';

my $invoice_id = LedgerSMB::API->post_payment_to_ap_invoice($myconfig,$lsmb,\%fields);

row_ok( table => 'ap',
        where => [   vendor_id => $vendor_id,
                     invnumber => $invoice_id ] ,
        tests => { 'eq' => { amount => '500', 
                          transdate => $date,
                           ponumber => $po_transaction_id,
                         # ponumber => $purchase_order_id,
                               paid => 500 }
           },
        label => "Payment on invoice no. $invoice_id successfully posted, ap table has correct amount, date and PO number for this invoice and vendor."
    );

