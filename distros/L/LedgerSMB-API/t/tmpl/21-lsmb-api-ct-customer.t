#!perl -T

my $email = 'tester@example.net';
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
   tax_account_field_name => 'tax_2330',
  tax_account_field_value => 1,
                     name => 'The Testing Group',
                  contact => 'Testy Tester',
                 address1 => '123 Main Street',
                 address2 => '',
                     city => 'Decatur',
                    state => 'GA',
                  zipcode => '30032',
                    fname => 'Testy',
                    lname => 'Tester',
                    phone => '770-250-5192',
                    email => $email, 
                startdate => $date
                );

my $customer_id = LedgerSMB::API->create_new_customer($myconfig,$lsmb,\%fields);
# print STDERR "The \$result is: $result \n";

row_ok( table => 'customer',
        where => [ id => $customer_id ],
        tests => { 'eq' => { address1 => '123 Main Street',
                                email => $email,
                                phone => '770-250-5192', 
                                 city => 'Decatur' }
           },
        label => "customer no. $customer_id successfully inserted into LSMB application."
    );

# diag( "Testing LedgerSMB::API $LedgerSMB::API::VERSION, Perl $], $^X" );
