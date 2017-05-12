#!perl -T

my $email = 'hesco-test5@greens.org';
use lib qw( lib );
use Test::More tests => 4;
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

=head2 notes 

partnumber => $products_model,
onhand => $products_quantity,
description => $products_name,
weight => $products_weight,
listprice => $products_price,
sellprice => $products_price,
IC_inventory => '1001--Stock',
IC_income => '4000--Sales',
IC_expense => '5000--Materials purchsed',
IC_tax_2202 => '2202',
taxaccounts => '2202',
item => 'part',
unit => '',

https://hostname/ledgersmb/ic.pl?path=bin/mozilla&action=add&level=Goods%20%26%20Services--Add%20Part&login=LSMB_USER&timeout=3600&sessionid=&js=1&item=part

https://hostname/ledgersmb/ic.pl?path=bin/mozilla&action=add&level=Goods%20%26%20Services--Add%20Service&login=LSMB_USER&timeout=3600&sessionid=&js=1&item=service

https://hostname/ledgersmb/oe.pl?path=bin/mozilla&action=add&level=Order%20Entry--Sales%20Order&login=LSMB_USER&timeout=3600&sessionid=&js=1&type=sales_order

=cut

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

my $part_id = LedgerSMB::API->create_new_part($myconfig,$lsmb,\%fields);

row_ok( table => 'parts',
        where => [ partnumber => $partnumber ],
        tests => { 'eq' => { description => 'Widget, single',
                               sellprice => '0.25',
                                lastcost => '0.098' }
           },
        label => "Part no. $part_id successfully inserted into LSMB inventory."
    );

# diag( "Testing LedgerSMB::API $LedgerSMB::API::VERSION, Perl $], $^X" );

