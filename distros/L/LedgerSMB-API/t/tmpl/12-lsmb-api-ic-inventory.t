#!perl -T

my $email = 'hesco-test5@greens.org';
use lib qw( lib );
use Test::More tests => 10;
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

my $partnumber = 'Widget-0001';
%fields = (
                     item => 'part',
                 orphaned => 1,
              taxaccounts => '2150',
           selectcurrency => 'USD',
               partnumber => $partnumber,
              description => 'Widget, single',
                IC_income => '4410--General Sales',
               IC_expense => '5020--Purchases',
             IC_inventory => '1520--Inventory',
              IC_tax_2150 => 1,
  IC_tax_2150_description => '2150--Sales Tax',
              priceupdate => $date,
                sellprice => '0.25',
                listprice => '',
                 lastcost => '0.098',
                   markup => '',
               weightunit => 'lbs',
            customer_rows => 1,
           makemodel_rows => 1,
            assembly_rows => 1,
                    login => 'LSMB_USER',
                     path => 'bin/mozilla',
                );

# Create a new part
my $part_id = LedgerSMB::API->create_new_part($myconfig,$lsmb,\%fields);
# diag("The part_id is: $part_id");

row_ok( table => 'parts',
        where => [ partnumber => $partnumber ],
        tests => { 'eq' => { description => 'Widget, single',
                               sellprice => '0.25',
                                lastcost => '0.098' }
           },
        label => "Part no. $part_id successfully inserted into LSMB inventory."
    );

my $partnumber = 'Widgets-0250';
%fields = (
                 orphaned => 1,
              taxaccounts => '2150',
           selectcurrency => 'USD',
               partnumber => $partnumber,
              description => 'Widgets, 250 to the pack',
          selectIC_income => '4410--General Sales',
                IC_income => '4410--General Sales',
              IC_tax_2150 => 1,
  IC_tax_2150_description => '2150--Sales Tax',
                    notes => '',
                oldmarkup => '1,215.8',
              priceupdate => $date,
                sellprice => '62.50',
                listprice => 'NaN.00',
                 lastcost => '24.50',
                   markup => '1,215.8',
               weightunit => 'lbs',
           customercurr_1 => 'USD',
            customer_rows => 1,
           makemodel_rows => 1,
             partnumber_1 => $part_id,
           # partnumber_1 => 'Widget-0001',
              sellprice_1 => '0.25',
               lastcost_1 => '0.098',
                 weight_1 => 0,
          runningnumber_1 => 1,
                     id_1 => '',
                    qty_1 => 250,
                    bom_1 => 1,
                    adj_1 => 1,
            description_1 => 'widget, single, all purpose',
            assembly_rows => 2,
                  nextsub => 'edit_assemblyitem',
                    login => 'LSMB_USER',
                     path => 'bin/mozilla',
                );

# Create a new Assembly 
my $assy_250_part_id = LedgerSMB::API->create_new_assembly($myconfig,$lsmb,\%fields);

row_ok( table => 'parts',
        where => [ partnumber => $assy_250_part_id ],
        tests => { 'eq' => { description => 'Widgets, 250 to the pack',
                               sellprice => '62.5', 
                                lastcost => '24.5' }
           },
        label => "Assembly no. $assy_250_part_id successfully inserted into LSMB inventory."
    );

$fields{'partnumber'} = 'Widgets-0500';
$fields{'description'} = 'Widgets, 500 to the pack';
$fields{'sellprice'} = '125.00';
$fields{'listprice'} = 'NaN.00';
$fields{'lastcost'} = '49.00';
$fields{'qty_1'} = '500';

# Create another new Assembly 
my $assy_500_part_id = LedgerSMB::API->create_new_assembly($myconfig,$lsmb,\%fields);

row_ok( table => 'parts',
        where => [ partnumber => $assy_500_part_id ],
        tests => { 'eq' => { description => 'Widgets, 500 to the pack',
                               sellprice => '125', 
                                lastcost => '49' }
           },
        label => "Assembly no. $assy_500_part_id successfully inserted into LSMB inventory."
    );

$fields{'partnumber'} = 'Widgets-1000';
$fields{'description'} = 'Widgets, 1000 to the pack';
$fields{'sellprice'} = '250.00';
$fields{'listprice'} = 'NaN.00';
$fields{'lastcost'} = '98.00';
$fields{'qty_1'} = '1000';

# Create still another new Assembly 
my $assy_1000_part_id = LedgerSMB::API->create_new_assembly($myconfig,$lsmb,\%fields);

row_ok( table => 'parts',
        where => [ partnumber => $assy_1000_part_id ],
        tests => { 'eq' => { description => 'Widgets, 1000 to the pack',
                               sellprice => '250', 
                                lastcost => '98' }
           },
        label => "Assembly no. $assy_1000_part_id successfully inserted into LSMB inventory."
    );

%fields = ();

%fields = (
                  taxable => 1,
   tax_account_field_name => 'tax_2150',
  tax_account_field_value => '2150--Sales Tax',
                     name => 'The Widget Source',
                  contact => 'Testy Tester',
                 address1 => '123 Widget Central',
                 address2 => '',
                     city => 'Decatur',
                    state => 'GA',
                  zipcode => '30032',
                    fname => 'Helpful',
                    lname => 'Salesman',
                    phone => '770-555-1212',
                    email => $email,
                startdate => $date
                );

# Create a new vendor
my $vendor_id = LedgerSMB::API->create_new_vendor($myconfig,$lsmb,\%fields);

row_ok( table => 'vendor',
        where => [ email => $email ] ,
        tests => { 'eq' => { address1 => '123 Widget Central',
                                phone => '770-555-1212',
                                 city => 'Decatur' }
           },
        label => "vendor no. $vendor_id successfully inserted into LSMB application."
    );

%fields = ();

# my $part_id = '10119';
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
             oldvendor => 'The Widget Source--10143',
              currency => 'USD',
       defaultcurrency => 'USD',
                 forex => 0,
                vendor => 'The Widget Source--10143',
             transdate => $date,
          oldtransdate => $date,
                  path => 'bin/mozilla',
                 login => 'LSMB_USER',
              rowcount => 2,
              oldqty_1 => 5102,
                  id_1 => $part_id,
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

# Create a Purchase Order
my $purchase_order_id = LedgerSMB::API->create_new_purchase_order($myconfig,$lsmb,\%fields);

row_ok( table => 'oe',
        where => [   vendor_id => $vendor_id,
                     ordnumber => $purchase_order_id ] ,
        tests => { 'eq' => { amount => '500',
                          transdate => $date }
           },
        label => "purchase order no. $purchase_order_id successfully inserted into LSMB application, oe table has correct amount and date for this order and vendor."
    );

row_ok(   sql => "SELECT * FROM orderitems oi LEFT JOIN oe ON oi.trans_id = oe.id WHERE parts_id = $part_id AND oe.ordnumber = $purchase_order_id",
        tests => { 'eq' => { sellprice => '0.098' }
           },
        label => "purchase order no. $purchase_order_id successfully inserted into LSMB application, orderitems returns correct sellprice for order and part ids."
    );

my $sql = "SELECT id FROM oe WHERE ordnumber = $purchase_order_id";
my $sth = $lsmb->{'dbh'}->prepare($sql);
$sth->execute();
my ($po_transaction_id) = $sth->fetchrow_array();

$fields{'po_transaction_id'} = $po_transaction_id;
$fields{'AP'} = '2100--Accounts Payable';
# Generate an invoice from a purchase order
# my $invoice_id = LedgerSMB::API->generate_invoice_from_purchase_order($myconfig,$lsmb,\%fields);

# row_ok( table => 'ap',
#         where => [   vendor_id => $vendor_id,
#                      invnumber => $invoice_id ] ,
#         tests => { 'eq' => { amount => '500',
#                           transdate => $date,
#                            ponumber => $po_transaction_id }
#            },
#         label => "Inv# $invoice_id posted from PO, ap table has correct amount, date and PO number for this invoice and vendor."
#     );

# Create another invoice, and post a payment to it.

$fields{'AP'} = '2100'; # --Accounts Payable';
$fields{'paidaccounts'} = '1';
$fields{'datepaid_1'} = $date;
$fields{'source_1'} = '';
$fields{'memo_1'} = '';
$fields{'paid_1'} = '500';
$fields{'AP_paid_1'} = '2680--Loans from Shareholders';

$fields{acctrans}{$po_transaction_id}{'2680'}{'amount'} = '500';

# Post a payment to an invoice
my $invoice_id = LedgerSMB::API->post_payment_to_ap_invoice($myconfig,$lsmb,\%fields);

row_ok( table => 'ap',
        where => [   vendor_id => $vendor_id,
                     invnumber => $invoice_id ] ,
        tests => { 'eq' => { amount => '500',
                          transdate => $date,
                           ponumber => $po_transaction_id,
                               paid => 500 }
           },
        label => "Payment posted for inv# $invoice_id, ap table has correct amount, date and PO number for this invoice and vendor."
    );


