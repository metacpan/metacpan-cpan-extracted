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
                    fname => 'Testy',
                    lname => 'Tester',
                    phone => '770-555-1212',
                    email => $email, 
                startdate => $date
                );

my $vendor_id = LedgerSMB::API->create_new_vendor($myconfig,$lsmb,\%fields);
# print STDERR "The \$result is: $result \n";

row_ok( table => 'vendor',
        where => [ email => $email ] ,
        tests => { 'eq' => { address1 => '123 Widget Central',
                                phone => '770-555-1212', 
                                 city => 'Decatur' }
           },
        label => "vendor no. $vendor_id successfully inserted into LSMB application."
    );

# diag( "Testing LedgerSMB::API $LedgerSMB::API::VERSION, Perl $], $^X" );
