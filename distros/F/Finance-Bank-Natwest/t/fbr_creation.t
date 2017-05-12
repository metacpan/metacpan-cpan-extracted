#!/usr/bin/perl -w

use strict;

use lib 't/lib';

use Carp;
use Test::More tests => 15;
use Test::Exception;
use Mock::NatwestWebServer;
use Finance::Bank::Natwest::CredentialsProvider::Constant;

my $nws = Mock::NatwestWebServer->new();
$nws->set_host('www.rbsdigital.com');
$nws->add_account( dob => '010179', uid => '0001',
                   pin => '4321', pass => 'Password' );

use_ok( 'Finance::Bank::RBoS' );


dies_ok {
   my $fbn = Finance::Bank::RBoS->new();
} 'invalid credential parameters: expected to fail';

my $cred_obj = Finance::Bank::Natwest::CredentialsProvider::Constant->new(
    customer_no => '0101790001', password => 'Password', pin => '4321'
);

dies_ok {
   my $fbn = Finance::Bank::RBoS->new( 
      credentials => $cred_obj,
      credentials_options => undef
   );
} 'invalid credential parameters: expected to fail';

dies_ok {
   my $fbn = Finance::Bank::RBoS->new( 
      credentials => $cred_obj,
      credentials_options => {}
   );
} 'invalid credential parameters: expected to fail';

dies_ok {
   my $fbn = Finance::Bank::RBoS->new( 
      credentials => $cred_obj,
      credentials_options => { customer_no => '0101790001',
                               password => 'Password',
			       pin => '4321'} 
   );
} 'invalid credential parameters: expected to fail';

dies_ok {
   my $fbn = Finance::Bank::RBoS->new( credentials => 'Constant' );
} 'invalid credential parameters: expected to fail';

dies_ok {
   my $fbn = Finance::Bank::RBoS->new( credentials => 'Callback' );
} 'invalid credential parameters: expected to fail';

dies_ok {
   my $fbn = Finance::Bank::RBoS->new( credentials => 'GPG' );
} 'invalid credential parameters: expected to fail';

dies_ok {
   my $fbn = Finance::Bank::RBoS->new(
      credentials => 'Constant',
      credentials_options => {}
   );
} 'invalid credential parameters: expected to fail';

dies_ok {
   my $fbn = Finance::Bank::RBoS->new(
      credentials => 'Callback',
      credentials_options => {}
   );
} 'invalid credential parameters: expected to fail';

dies_ok {
   my $fbn = Finance::Bank::RBoS->new( credentials_options => {} );
} 'invalid credentials parameters: expected to fail';


{
   my $fbn = Finance::Bank::RBoS->new( credentials => 'Constant',
                                          credentials_options => { 
                                             customer_no => '0101790001',
                                             password => 'Password',
				             pin => '4321'
				       } );

   isa_ok( $fbn, 'Finance::Bank::RBoS' );

   foreach my $method (qw( accounts )) {
      can_ok( $fbn, $method );
   }

   my $accounts = $fbn->accounts();

   is_deeply( $accounts,
      [ { name => 'CURRENT', account => '60123456', sortcode => '60-01-27',
          balance => '100', available => '100' },
	{ name => 'STUDENT', account => '60654321', sortcode => '60-01-27',
	  balance => '-250', available => '750' },
      ],
      'Got expected account summary (ref)' );

   my @accounts = $fbn->accounts();
   
   is_deeply( \@accounts,
      [ { name => 'CURRENT', account => '60123456', sortcode => '60-01-27',
          balance => '100', available => '100' },
	{ name => 'STUDENT', account => '60654321', sortcode => '60-01-27',
	  balance => '-250', available => '750' },
      ],
      'Got expected account summary (list)' );

}
