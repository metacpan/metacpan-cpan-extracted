package LedgerSMB::API;

use warnings;
use strict;

BEGIN {
  $ENV{'PATH'} = '/bin';
  my $lsmb_path = `/bin/cat /etc/ledgersmb_path`;
  if(!defined($lsmb_path)){
    $lsmb_path = `/bin/cat /etc/ledgersmb_path`;
  }
  push @INC, $lsmb_path;
}

use LedgerSMB::Form;
use LedgerSMB::User;
use LedgerSMB::Sysconfig;
use LedgerSMB::OE;
use LedgerSMB::CT;
use LedgerSMB::IC;
use LedgerSMB::IR;
# use LedgerSMB::IS;
use Data::Dumper;
use utf8;
use Encode;

=head1 NAME

LedgerSMB::API - Exposing the LedgerSMB API to Integrators!

=head1 VERSION

Version 0.04a

=cut

our $VERSION = '0.04a';

=head1 SYNOPSIS

    use LedgerSMB::API;

    my($myconfig,$lsmb) = LedgerSMB::API->new_lsmb($login_name) 

Generally the methods offered here can be invoked in the form:

    my ${entity}_id = LedgerSMB::API->create_new_{entity}($myconfig,$lsmb,\%fields);

Such create_new_ methods exist so far for entities: vendor,
customer, part, assembly, order,

For accessors try:

    my ${entity}_id = LedgerSMB::API->id_existing_{entity}($class,$myconfig,$form,$fields);

Accessors now working for the following entities: vendor and customer.

And a key feature being direct access to the LedgerSMB database,
using all the magic of DBI and DBD::Pg.

    my $dbh = $lsmb->{'dbh'};

    ...

=head1 CAVEAT

LedgerSMB is a recent fork of the SQL-Ledger codebase,
developed by Dieter Simander.  This module is being tested
against LedgerSMB 1.2.9.  LedgerSMB developers are warning of
significant interface changes in upcoming development.  These
methods may or may not work using the pre-fork SQL-Ledger code.
Testers, tests and patches to accomodate compatibility of the
legacy code base are welcome.  However currently developers
are focused for the moment on simply exposing an API for the
current stable version of the forked codebase.

The existing web interface offers a dizzying array of options
you can set for an order, a customer, an invoice, etc.
The methods offered here screen incoming data for legal field
names and pass user values without validation, straight into
the database using the save() routines offered by the LedgerSMB
code base.

CAVEAT EMPTOR: These routines pass data, WITHOUT VALIDATION,
straight into your accounting database.  This means the user
is responsible for cleaning their data and protecting the
integrity of their accounting database.  As this module is in
its early phases of its development, folks are urged to test
this code against COPIES of their existing set of real books
and to report anomolies observed in their access and use of
automated data in comparison with data entered through the
more mature web interface.

Study the test suite for clues about how to use these methods
to integrate an existing ecommerce application with LedgerSMB,
permitting your ecommerce application to communicate with your
accounting system.  Help us test and develop this.  Thanks.

=head1 METHODS 

The following functions are available so far: 

* new_lsmb()
* create_new_vendor()
* id_existing_vendor()
* create_new_customer()
* id_existing_customer()
* create_new_part() 
* create_new_assembly()
* create_new_purchase_order()
* generate_invoice_from_purchase_order()
* create_new_sales_order()

The following functions are priority for coming development now:

* generate_invoice_from_sales_order()
* post_payment_to_ap_invoice()
* post_payment_to_ar_invoice()
* generate_account_statement()

=cut

=head2 my ($myconfig,$lsmb) = LedgerSMB::API->new_lsmb($login_name) 

This initiates a connection to the LedgerSMB database and to its
configuration as the user passed as an argument on invocation.
This method returns a configuration hash and a LedgerSMB Form
object, including access to its database handle and to the 68
methods made available by the LedgerSMB::Form module.

=cut

sub new_lsmb {
  my $class = shift;
  my $login = shift;

  # Connect to LSMB
  # print "connecting to LSMB\n" if $verbose;
  my $form = new Form;
  $form->{login} = $login;
  
  #Create a new form object
  our $myconfig = new LedgerSMB::User("$form->{login}");
  $form->db_init($myconfig);
  # bless $class, $form;
  return $myconfig,$form;

}

=head2 LedgerSMB::API->create_new_{entity}() functions generally

These methods, except as noted below, generally accept a
$myconfig object, a $form object and a $fields hashreference on
its interface.  For each field name valid in the creation of the
entity in the LedgerSMB system, the value associated with that
key in the incoming $fields hash is encoded and assigned to an
$entity object, and then the $entity object is used to create a
new entity in the accounting system.  If the 'taxable' key is
set to a true value, the values for 'tax_account_field_name',
'tax_account_field_value' and 'taxaccounts' are used to indicate
how the entity ought to be taxed.

For entities with multiple line numbers, like orders or
invoices, assemblies, or even parts (from multiple vendors at
various prices), field names will be in the form of fieldname_n,
with n indicating the line number for the invoice.

It is generally possible to create valid entities in the
accounting system populating only a fraction of the available
fields.

=head2 my $customer_id = LedgerSMB::API->create_new_customer($myconfig,$lsmb,\%fields);

Valid keys for the %fields hash include: customernumber, name,
address1, address2, city, state, zipcode, country, contact,
phone, fax, email, cc, none, shiptoname, shiptoaddress1,
shiptoaddress2, shiptocity, shiptostate, shiptozipcode,
shiptocountry, shiptocontact, shiptophone, shiptofax,
shiptoemail, taxincluded, startdate, enddate, creditlimit,
terms, discount, taxnumber, sic_code, bic, iban, curr,
employee, notes, taxable, tax_account_field_name and
tax_account_field_value.

=cut

sub create_new_customer {
  my $class = shift;
  my $myconfig = shift;
  my $form = shift;
  my $fields = shift;
  my $customer_id = id_existing_customer($class,$myconfig,$form,$fields);
  if($customer_id) { return $customer_id; }

  my $customer = new Form;
  $customer->{dbh} = $form->{dbh};

  my @valid_fields = qw( customernumber name address1 address2 city state zipcode country contact phone fax email cc none shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact shiptophone shiptofax shiptoemail taxincluded startdate enddate creditlimit terms discount taxnumber sic_code bic iban curr employee notes );

  foreach my $valid_field (@valid_fields){
    if($valid_field =~ m/date/){
      $customer->{$valid_field} = $fields->{$valid_field};
    } else {
      $customer->{$valid_field} = encode("ascii",$fields->{$valid_field});
    }
  }

  if ($fields->{'taxable'}){
    $customer->{$fields->{'tax_account_field_name'}} = $fields->{'tax_account_field_value'};
    $customer->{taxaccounts} = $fields->{'taxaccounts'};
  }

  CT->save_customer(\%{$myconfig}, \%$customer);

  # print Dumper($customer);
  $customer_id = id_existing_customer($class,$myconfig,$form,$fields);
  if($customer_id) {
    return $customer_id;
  } else {
    return 0;
  }

}

=head2 my $vendor_id = LedgerSMB::API->create_new_vendor($myconfig,$lsmb,\%fields);

Valid keys for the %fields hash include: vendornumber, name,
address1, address2, city, state, zipcode, country, contact,
phone, fax, email, cc, bcc, none, shiptoname, shiptoaddress1,
shiptoaddress2, shiptocity, shiptostate, shiptozipcode,
shiptocountry, shiptocontact, shiptophone, shiptofax,
shiptoemail, taxincluded, startdate, enddate, creditlimit,
terms, discount, taxnumber, gifi_accno, sic_code, bic, iban,
curr, notes, action, id, taxaccounts, path, login, sessionid,
callback and db.

=cut

sub create_new_vendor {
  my $class = shift;
  my $myconfig = shift;
  my $form = shift;
  my $fields = shift;
  my $vendor_id = id_existing_vendor($class,$myconfig,$form,$fields);
  if($vendor_id) { return $vendor_id; }

  my $vendor = new Form;
  $vendor->{dbh} = $form->{dbh};

  my @valid_fields = qw( vendornumber name address1 address2 city state zipcode country contact phone fax email cc bcc none shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact shiptophone shiptofax shiptoemail taxincluded startdate enddate creditlimit terms discount taxnumber gifi_accno sic_code bic iban curr notes action );

  my @valid_hidden_fields = qw( id taxaccounts path login sessionid callback db );

  foreach my $valid_field (@valid_fields){
    if($valid_field =~ m/date/){
      $vendor->{$valid_field} = $fields->{$valid_field};
    } else {
      $vendor->{$valid_field} = encode("ascii",$fields->{$valid_field});
    }
  }

  if ($fields->{'taxable'}){
    $vendor->{$fields->{'tax_account_field_name'}} = $fields->{'tax_account_field_value'};
    $vendor->{taxaccounts} = $fields->{'taxaccounts'};
  }

  CT->save_vendor(\%{$myconfig}, \%$vendor);

  # print Dumper($vendor);
  $vendor_id = id_existing_vendor($class,$myconfig,$form,$fields);
  if($vendor_id) {
    return $vendor_id;
  } else {
    return 0;
  }

}

=head2 my $part_id = LedgerSMB::API->create_new_part($myconfig,$lsmb,\%fields);

Valid keys for the %fields hash include: id, item, title,
makemodel, alternate, onhand, orphaned, taxaccounts,
rowcount, baseassembly, project_id, partnumber, description,
IC_inventory, selectIC, IC_income, selectIC_income,
IC_expense, selectIC_expense, notes, priceupdate, sellprice,
listprice, lastcost, markup, oldmarkup, avgcost, unit, weight,
weightunit, rop, bin, image, microfiche, drawing, selectvendor,
selectcurrency, selectcustomer, selectpricegroup, customer_rows,
makemodel_rows, vendor_rows, login, path, sessionid, callback,
previousform, isassemblyitem.

Plus the IC_tax_nnnn and IC_tax_nnnn_description.  

The price matrix for a part for each line number n, uses
fields in the form: make_n, model_n, vendor_n, partnumber_n,
lastcost_n, vendorcurr_n, leadtime_n, customer_n, pricebreak_n,
customerprice_n, customercurr_n, validfrom_n and validto_n.

=cut

sub create_new_part {
  my $class = shift;
  my $myconfig = shift;
  my $form = shift;
  my $fields = shift;

  my $part = new Form;
  $part->{dbh} = $form->{dbh};

  my @valid_fields = qw( id item title makemodel alternate onhand orphaned taxaccounts rowcount baseassembly project_id partnumber description IC_inventory selectIC IC_income selectIC_income IC_expense selectIC_expense notes priceupdate sellprice listprice lastcost markup oldmarkup avgcost unit weight weightunit rop bin image microfiche drawing selectvendor selectcurrency selectcustomer selectpricegroup customer_rows makemodel_rows vendor_rows login path sessionid callback previousform isassemblyitem );

  foreach my $valid_field (@valid_fields){
    $part->{$valid_field} = encode("ascii",$fields->{$valid_field}) if(defined($fields->{$valid_field}));
  }

  my $valid_tax_field = 'IC_tax_';
  foreach my $key (keys %$fields){
    if($key =~ m/$valid_tax_field/ && $key !~ m/description/){
      $part->{$key} = encode("ascii",$fields->{$key});
      $part->{$key . '_description'} = encode("ascii",$fields->{$key . '_description'});
    }
  }

  my @valid_price_matrix_fields = qw( make_ model_ vendor_ partnumber_ lastcost_ vendorcurr_ leadtime_ customer_ pricebreak_ customerprice_ customercurr_ validfrom_ validto_ );
  # Now do the price matrix
  $part->{'customer_rows'} = 0;
  for my $i (1 .. $part->{'customer_rows'}) {
    foreach my $valid_price_matrix_field (@valid_price_matrix_fields){
      if (defined($fields->${"pricebreak_$i"})) {
        # We have a price break
        $part->{"pricebreak_$i"} = $fields->${"pricebreak_$i"};
        $part->{"customerprice_$i"} = $fields->${"customerprice_$i"};
        $part->{customer_rows} += 1;
      } else {
        # If we find a zero price best to bail out
        last;
      }
    }
  }
  IC->save(\%$myconfig, \%$part);
  # print Dumper($part);
  return $part->{id};

}

=head2 my $assembly_id = LedgerSMB::API->create_new_assembly($myconfig,$lsmb,\%fields);


=cut

sub create_new_assembly {
  my $class = shift;
  my $myconfig = shift;
  my $form = shift;
  my $fields = shift;

  my $assy = new Form;
  $assy->{dbh} = $form->{dbh};
  $assy->{'item'} = 'assembly';
  $assy->{'title'} = 'Add Assembly';
  # $assy->{''} = '';
  # $assy->{''} = '';
  # $assy->{''} = '';
  $assy->{customer_id} = $fields->{'customer_id'};

  my @valid_visible_fields = qw( selectcurrency partnumber description notes IC_income priceupdate sellprice listprice markup unit stock rop bin image microfiche drawing action  );

  my @valid_price_group_fields = qw( customer_ pricebreak_ customerprice_ customercurr_ validfrom_ validto_ );

  my @valid_components_fields_existing_parts = qw( runningnumber_ qty_ bom_ adj_ partnumber_ id_ sellprice_ listprice_ lastcost_ weight_ assembly_ unit_ description_ );

  my @valid_makemodel_fields = qw( make_ model_ );

  my @valid_components_fields_pending_parts = qw( qty_ partnumber_ description_ id_ sellprice_ listprice_ lastcost_ weight_ assembly_ );

  my @valid_hidden_fields = qw( id item title makemodel alternate onhand orphaned baseassembly project_id selectcustomer selectpricegroup selectIC_income oldmarkup lastcost weight weightunit nextsub selectassemblypartsgroup login path sessionid callback previousform isassemblyitem taxaccounts );

  my @rowcounts = qw( rowcount customer_rows makemodel_rows assembly_rows );

  my @fields = ();
  push @fields, @valid_visible_fields;
  push @fields, @valid_hidden_fields;
  push @fields, @rowcounts;

  foreach my $field ( @fields ){
    $assy->{$field} = encode("ascii",$fields->{$field}) if(defined($fields->{$field}));
  }

  foreach my $i ( 1..$fields->{'makemodel_rows'} ){
    foreach my $field ( @valid_makemodel_fields ) {
      $assy->{$field . $i} = encode("ascii",$fields->{$field . $i}) if(defined($fields->{$field . $i}));
    }    
  }

  foreach my $i ( 1..$fields->{'customer_rows'} ){
    foreach my $field ( @valid_price_group_fields ) {
      $assy->{$field . $i} = encode("ascii",$fields->{$field . $i}) if(defined($fields->{$field . $i}));
    }    
  }

  foreach my $i ( 1..$fields->{'assembly_rows'} ){
    foreach my $field ( @valid_components_fields_existing_parts ) {
      $assy->{$field . $i} = encode("ascii",$fields->{$field . $i}) if(defined($fields->{$field . $i}));
    }    
  }

  my $valid_tax_field = 'IC_tax_';
  foreach my $key (keys %$fields){
    if($key =~ m/$valid_tax_field/ && $key !~ m/description/){
      $assy->{$key} = encode("ascii",$fields->{$key});
      $assy->{$key . '_description'} = encode("ascii",$fields->{$key . '_description'});
    }
  }

  IC->save(\%$myconfig,\%$assy);
  return $assy->{'partnumber'};

}

=head2 my $purchase_order_id = LedgerSMB::API->create_new_purchase_order($myconfig,$lsmb,\%fields);

Valid keys for your %fields hash include: id, type, formname,
media, format, printed, emailed, queued, vc, title, discount,
creditlimit, creditremaining, tradediscount, business,
recurring, shiptoname, shiptoaddress1, shiptoaddress2,
shiptocity, shiptostate, shiptozipcode, shiptocountry,
shiptocontact, shiptophone, shiptofax, shiptoemail, message,
email, subject, cc, bcc, taxaccounts, audittrail, oldcurrency,
selectpartsgroup, selectprojectnumber, oldinvtotal,
oldtotalpaid, vendor_id, oldvendor, selectcurrency,
defaultcurrency, forex, vendor, selectvendor, currency,
shippingpoint, shipvia, employee, quonumber, oldtransdate,
ordnumber, transdate, reqdate, ponumber, terms, notes, intnotes,
formname, selectformname, format, selectformat, media, copies,
groupprojectnumber, grouppartsgroup, sortby, action, rowcount,
callback, path, login and sessionid.

For populating each line item, n, of your purchase order,
the following fields are available:  runningnumber_n,
partnumber_n, description_n, qty_n, ship_n, unit_n, sellprice_n,
discount_n, reqdate_n, notes_n, serialnumber_n, oldqty_n,
orderitems_id_n, id_n, bin_n, weight_n, listprice_n, lastcost_n,
taxaccounts_n, pricematrix_n, sku_n, onhand_n, assembly_n,
inventory_accno_id_n, income_accno_id_n and expense_accno_id_n.

=cut

sub create_new_purchase_order {
  my $class = shift;
  my $myconfig = shift;
  my $form = shift;
  my $fields = shift;

  my $order = new Form;
  $order->{dbh} = $form->{dbh};
  $order->{type} = "purchase_order";
  $order->{vc} = "vendor";
  $order->{vendor_id} = $fields->{'vendor_id'};
  $order->{'rowcount'} = $fields->{'rowcount'};

  my @valid_fields = qw( id type formname media format printed emailed queued vc title discount creditlimit creditremaining tradediscount business recurring shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact shiptophone shiptofax shiptoemail message email subject cc bcc taxaccounts audittrail oldcurrency selectpartsgroup selectprojectnumber oldinvtotal oldtotalpaid vendor_id oldvendor selectcurrency defaultcurrency forex vendor selectvendor currency shippingpoint shipvia employee quonumber oldtransdate ordnumber transdate reqdate ponumber terms notes intnotes formname selectformname format selectformat media copies groupprojectnumber grouppartsgroup sortby action rowcount callback path login sessionid );

  my @valid_line_item_fields = qw( runningnumber_ partnumber_ description_ qty_ ship_ unit_ sellprice_ discount_ reqdate_ notes_ serialnumber_ oldqty_ orderitems_id_ id_ bin_ weight_ listprice_ lastcost_ taxaccounts_ pricematrix_ sku_ onhand_ assembly_ inventory_accno_id_ income_accno_id_ expense_accno_id_ );

  foreach my $field ( @valid_fields ){
    $order->{$field} = encode("ascii",$fields->{$field}) if(defined($fields->{$field}));
  }

  foreach my $i ( 1..$fields->{'rowcount'} ){
    foreach my $field ( @valid_line_item_fields ) {
      $order->{$field . $i} = encode("ascii",$fields->{$field . $i}) if(defined($fields->{$field . $i}));
    }    
  }

  OE->save(\%$myconfig,\%$order);
  return $order->{'ordnumber'};

  # my $sql = "SELECT id FROM oe WHERE ordnumber = '" . $order->{'ordnumber'} . "'";
  # my $sth = $form->{'dbh'}->prepare($sql);
  # $sth->execute();
  # my ($po_transaction_id) = $sth->fetchrow_array();
  # $order->{'po_transaction_id'} = $po_transaction_id;
  # my $invoice_id = LedgerSMB::API->generate_invoice_from_purchase_order($myconfig,$form,\%$order);
  # return ($order->{'ordnumber'},$invoice_id);

}

=head2 ->generate_invoice_from_purchase_order()

Vaild keys include: id, type, formname, media, format,
printed, emailed, queued, vc, title, discount, creditlimit,
creditremaining, tradediscount, business, recurring, shiptoname,
shiptoaddress1, shiptoaddress2, shiptocity, shiptostate,
shiptozipcode, shiptocountry, shiptocontact, shiptophone,
shiptofax, shiptoemail, message, email, subject, cc, bcc,
taxaccounts, audittrail, oldcurrency, selectpartsgroup,
selectprojectnumber, oldinvtotal, oldtotalpaid, vendor_id,
oldvendor, selectcurrency, defaultcurrency, forex, vendor,
selectvendor, currency, shippingpoint, shipvia, employee,
quonumber, oldtransdate, closed, closed, ordnumber,
transdate, reqdate, ponumber, terms, notes, intnotes,
formname, selectformname, format, selectformat, media, copies,
groupprojectnumber, grouppartsgroup, sortby, action, rowcount,
callback, path, login, sessionid,

Valid keys for each line item include: oldqty_, orderitems_id_,
id_, bin_, weight_, listprice_, lastcost_, taxaccounts_,
pricematrix_, sku_, onhand_, assembly_, inventory_accno_id_,
income_accno_id_, expense_accno_id_, runningnumber_,
partnumber_, description_, qty_, ship_, unit_, sellprice_,
discount_, reqdate_, notes_, serialnumber_,

=cut

sub generate_invoice_from_purchase_order {
  my $class = shift;
  my $myconfig = shift;
  my $form = shift;
  my $fields = shift;

  my $invoice_ap = new Form;
  $invoice_ap->{'dbh'} = $form->{'dbh'};
  $invoice_ap->{'type'} = 'purchase_order';
  $invoice_ap->{'vc'} = 'vendor';
  $invoice_ap->{'AP'} = $fields->{'AP'};
  $invoice_ap->{'path'} = 'bin/mozilla';
  $invoice_ap->{'ponumber'} = $fields->{'po_transaction_id'};
  $invoice_ap->{'login'} = $form->{'login'};
  $invoice_ap->{'action'} = 'vendor_invoice';
  $invoice_ap->{'employee'} = $fields->{'employee'}; 

  my @valid_fields = qw( id type formname media format printed emailed queued vc title discount creditlimit creditremaining tradediscount business recurring shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact shiptophone shiptofax shiptoemail message email subject cc bcc taxaccounts audittrail oldcurrency selectpartsgroup selectprojectnumber oldinvtotal oldtotalpaid vendor_id oldvendor selectcurrency defaultcurrency forex vendor selectvendor currency shippingpoint shipvia employee quonumber oldtransdate closed closed ordnumber transdate reqdate ponumber terms notes intnotes formname selectformname format selectformat media copies groupprojectnumber grouppartsgroup sortby action rowcount callback path login sessionid );

  my @valid_line_item_fields = qw( oldqty_ orderitems_id_ id_ bin_ weight_ listprice_ lastcost_ taxaccounts_ pricematrix_ sku_ onhand_ assembly_ inventory_accno_id_ income_accno_id_ expense_accno_id_ runningnumber_ partnumber_ description_ qty_ ship_ unit_ sellprice_ discount_ reqdate_ notes_ serialnumber_ );

  foreach my $field ( @valid_fields ){
    $invoice_ap->{$field} = encode("ascii",$fields->{$field}) if(defined($fields->{$field}));
  }

  foreach my $i ( 1..$fields->{'rowcount'} ){
    foreach my $field ( @valid_line_item_fields ) {
      $invoice_ap->{$field . $i} = encode("ascii",$fields->{$field . $i}) if(defined($fields->{$field . $i}));
    }    
  }

  IR->post_invoice($myconfig,$invoice_ap);
  return $invoice_ap->{'invnumber'};

}

=head2 my $result = LedgerSMB::API->post_payment_to_ap_invoice($myconfig,$lsmb,\%fields);

Valid fields include: id, title, vc, type, terms, creditlimit,
creditremaining, closedto, locked, shipped, oldtransdate,
recurring, selectcurrency, defaultcurrency, taxaccounts,
audittrail, oldcurrency, selectpartsgroup, selectprojectnumber,
vendor_id, oldvendor, selectAP, selectcurrency, defaultcurrency,
forex, vendor, selectvendor, AP, currency, quonumber,
invnumber, ordnumber, transdate, duedate, ponumber, notes,
intnotes, import_text, cleared_1, paidaccounts, selectAP_paid,
oldinvtotal, oldtotalpaid, action, rowcount, callback, path,
login and sessionid.

The line items on a vendor invoice are described using these
fields: oldqty_, orderitems_id_, id_, bin_, weight_, listprice_,
lastcost_, taxaccounts_, pricematrix_, sku_, onhand_, assembly_,
inventory_accno_id_, income_accno_id_, expense_accno_id_,
runningnumber_, partnumber_, description_, qty_, unit_,
sellprice_, discount_, deliverydate_, notes_, serialnumber_,

Payments on Vendor Invoices are made using these fields:
datepaid_, source_, memo_, paid_ and AP_paid_.

=cut

sub post_payment_to_ap_invoice {
  my $class = shift;
  my $myconfig = shift; 
  my $form = shift;
  my $fields = shift;

  my $invoice_ap = new Form;
  $invoice_ap->{'dbh'} = $form->{'dbh'};
  $invoice_ap->{'type'} = 'purchase_order';
  $invoice_ap->{'vc'} = 'vendor';
  $invoice_ap->{'AP'} = $fields->{'AP'};
  $invoice_ap->{'path'} = 'bin/mozilla';
  $invoice_ap->{'ponumber'} = $fields->{'po_transaction_id'};
  $invoice_ap->{'login'} = $form->{'login'};
  $invoice_ap->{'action'} = 'vendor_invoice';
  $invoice_ap->{'employee'} = $fields->{'employee'}; 

  my @valid_fields = qw( id title vc type terms creditlimit creditremaining closedto locked shipped oldtransdate recurring selectcurrency defaultcurrency taxaccounts audittrail oldcurrency selectpartsgroup selectprojectnumber vendor_id oldvendor selectAP selectcurrency defaultcurrency forex vendor selectvendor AP currency quonumber invnumber ordnumber transdate duedate ponumber notes intnotes import_text cleared_1 paidaccounts selectAP_paid oldinvtotal oldtotalpaid action rowcount callback path login sessionid );

  my @valid_line_item_fields = qw( oldqty_ orderitems_id_ id_ bin_ weight_ listprice_ lastcost_ taxaccounts_ pricematrix_ sku_ onhand_ assembly_ inventory_accno_id_ income_accno_id_ expense_accno_id_ runningnumber_ partnumber_ description_ qty_ unit_ sellprice_ discount_ deliverydate_ notes_ serialnumber_ );

  my @valid_payment_fields = qw( datepaid_ source_ memo_ paid_ AP_paid_ );

  my ($field,$i);
  foreach $field ( @valid_fields ){
    $invoice_ap->{$field} = encode("ascii",$fields->{$field}) if(defined($fields->{$field}));
  }

  foreach $i ( 1..$fields->{'rowcount'} ){
    foreach $field ( @valid_line_item_fields ) {
      $invoice_ap->{$field . $i} = encode("ascii",$fields->{$field . $i}) if(defined($fields->{$field . $i}));
    }    
  }

  foreach $i ( 1..$fields->{'paidaccounts'} ){
    foreach $field ( @valid_payment_fields ) {
      $invoice_ap->{$field . $i} = encode("ascii",$fields->{$field . $i}) if(defined($fields->{$field . $i}));
    }    
  }

  IR->post_invoice($myconfig,$invoice_ap);
  return $invoice_ap->{'invnumber'};

}

=head2 my $sales_order_id = LedgerSMB::API->create_new_sales_order($myconfig,$lsmb,\%fields);

=cut

sub create_new_sales_order {
  my $class = shift;
  my $myconfig = shift;
  my $form = shift;
  my $fields = shift;
  # my $customer_id = id_existing_customer($class,$myconfig,$form,$fields);

  my $order = new Form;
  $order->{dbh} = $form->{dbh};
  $order->{type} = "sales_order";
  $order->{vc} = "customer";
  $order->{customer_id} = $fields->{'customer_id'};
  $order->{'rowcount'} = $fields->{'rowcount'};

  my @required_fields = qw( customer_id type vc rowcount forex );

  my @valid_visible_fields = qw( robots customer currency shippingpoint shipvia ordnumber transdate reqdate ponumber terms notes intnotes formname format media copies groupprojectnumber grouppartsgroup );

  my @valid_visible_line_item_fields = qw( runningnumber_ partnumber_ description_ qty_ ship_ unit_ sellprice_ discount_ );

  my @valid_hidden_line_item_fields = qw( oldqty_ orderitems_id_ id_ bin_ weight_ listprice_ lastcost_ taxaccounts_ pricematrix_ sku_ onhand_ assembly_ inventory_accno_id_ income_accno_id_ expense_accno_id_ );

  my @valid_hidden_fields = qw( id formname media format printed emailed queued title discount creditlimit creditremaining tradediscount business recurring selectcustomer oldcustomer selectcurrency defaultcurrency employee quonumber oldtransdate shiptoname shiptoaddress1 shiptoaddress2 shiptocity shiptostate shiptozipcode shiptocountry shiptocontact shiptophone shiptofax shiptoemail message email subject cc bcc taxaccounts audittrail oldcurrency selectpartsgroup selectprojectnumber oldinvtotal oldtotalpaid selectformname selectformat callback path login sessionid );

  my $field;
  foreach $field ( @valid_visible_fields, @valid_hidden_fields ){
    $order->{$field} = encode("ascii",$fields->{$field}) if(defined($fields->{$field}));
  }

  my @valid_line_item_fields;
  push @valid_line_item_fields, @valid_visible_line_item_fields;
  push @valid_line_item_fields, @valid_hidden_line_item_fields;
  foreach my $i ( 1..$fields->{'rowcount'} ){
    foreach $field ( @valid_line_item_fields ) {
      $order->{$field . $i} = encode("ascii",$fields->{$field . $i}) if(defined($fields->{$field . $i}));
    }    
  }

  OE->save(\%$myconfig,\%$order);
  return $order->{'ordnumber'};

}

=head2  $customer_id = id_existing_customer($class,$myconfig,$form,$fields);

=head2  $vendor_id = id_existing_vendor($class,$myconfig,$form,$fields);

This is a simple comparison of email addresses and returns
either 0, if no matches or the id for the requested vendor
or customer.  It is imagined that a more sophisticated
duplicate matching routine will be written on an installation
by installation basis over-riding this one.

=cut

sub id_existing_vendor {
  my $class = shift;
  my $myconfig = shift;
  my $form = shift;
  my $fields = shift;

  my $sql = "SELECT id FROM vendor WHERE email = ? ORDER BY id DESC LIMIT 1;";
  my $sth = $form->{'dbh'}->prepare($sql);
  $sth->execute($fields->{'email'});
  while (my ($id) = $sth->fetchrow_array()){
    if(defined($id)){
      return $id;
    } else {
      return 0;
    }
  }
}

sub id_existing_customer {
  my $class = shift;
  my $myconfig = shift;
  my $form = shift;
  my $fields = shift;

  my $sql = "SELECT id FROM customer WHERE email = ? ORDER BY id DESC LIMIT 1;";
  my $sth = $form->{'dbh'}->prepare($sql);
  $sth->execute($fields->{'email'});
  while (my ($id) = $sth->fetchrow_array()){
    if(defined($id)){
      return $id;
    } else {
      return 0;
    }
  }
}

=head1 AUTHOR

Nigel Titley and Hugh Esco, C<< <nigel at titley.com and hesco@campaignfoundations.com> >>

=head1 KNOWN BUGS

=head2 create_new_assembly() broken

This routine currently can successfully create a record in
the parts table, but fails to create one in the assembly
table, as is done from the browser interface using the
Goods_&_Services->Add_Assembly screen.  As a consequence the
new assembly created with this method is unavailable in the
Goods_&_Services->Stock_Assembly screen.

=head2 Your bug reports welcome

Please report any bugs or feature requests to
C<bug-ledgersmb-api at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LedgerSMB-API>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LedgerSMB::API

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LedgerSMB-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LedgerSMB-API>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LedgerSMB-API>

=item * Search CPAN

L<http://search.cpan.org/dist/LedgerSMB-API>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009 Nigel Titley and Hugh Esco, all rights reserved.

This program is released under the following license: gpl

=cut

1; # End of LedgerSMB::API
