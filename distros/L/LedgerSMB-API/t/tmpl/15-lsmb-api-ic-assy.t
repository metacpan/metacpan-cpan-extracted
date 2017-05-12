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

my $partnumber = 'Widgets-250';
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
              priceupdate => $date,
                sellprice => '62.50',
                listprice => 'NaN.00',
                 lastcost => '37.00',
                   markup => '1,215.8',
               weightunit => 'lbs',
             partnumber_1 => 'YMD-0001',
              sellprice_1 => '0.25',
               lastcost_1 => '0.148',
                 weight_1 => 0,
          runningnumber_1 => 1,
                    qty_1 => 250,
                    bom_1 => 1,
                    adj_1 => 1,
            description_1 => 'widget, single, all purpose',
           customercurr_1 => 'USD',
            customer_rows => 1,
           makemodel_rows => 1,
            assembly_rows => 2,
                  nextsub => 'edit_assemblyitem',
                    login => 'LSMB_USER',
                     path => 'bin/mozilla',
                );

my $part_id = LedgerSMB::API->create_new_assembly($myconfig,$lsmb,\%fields);

row_ok( table => 'parts',
        where => [ partnumber => $partnumber ] ,
        tests => { 'eq' => { description => 'Widgets, 250 to the pack',
                               sellprice => '62.5', 
                                lastcost => '37' }
           },
        label => "Assembly no. $part_id successfully inserted into LSMB inventory."
    );

# diag( "Testing LedgerSMB::API $LedgerSMB::API::VERSION, Perl $], $^X" );
