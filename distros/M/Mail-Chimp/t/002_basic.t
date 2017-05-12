# -*- perl -*-

# t/002_basic.t - login
use strict;
use warnings;
use Test::More;
use Data::Dumper;

unless ( $ENV{MAILCHIMP_APIKEY} 
         or ($ENV{MAILCHIMP_USERNAME} and $ENV{MAILCHIMP_PASSWORD}) ) {
    plan skip_all => 'Provide $ENV{MAILCHIMP_APIKEY} or $ENV{MAILCHIMP_USERNAME} and $ENV{MAILCHIMP_PASSWORD} to run basic tests';
}
else {
    plan 'no_plan';
}

use_ok( 'Mail::Chimp::API' );

my $chimp = Mail::Chimp::API->new( 
    api_version => 1.2,
    $ENV{MAILCHIMP_APIKEY}
    ? (apikey   => $ENV{MAILCHIMP_APIKEY})
    : (username => $ENV{MAILCHIMP_USERNAME},
       password => $ENV{MAILCHIMP_PASSWORD}
      )
    );
my $lists = $chimp->lists;
diag(Dumper $lists);
#TODO 
#  Need to test the test bellow to make sure it still works. 
#  Not really happy with these test. I know we can not really test the funcitons, but we need better tests
#  then these.
#my $chimp = Mail::Chimp::API->new( api_key => $ENV{MAILCHIMP_APIKEY}, debug => $ENV{MAILCHIMP_DEBUG} );
#
#my $lists = $chimp->all_lists();
#
#{
#    my $list = $lists->[0];
#    diag("List name: ".$list->name);
#    my $email = 'drew@drewtaylor.com';
#    my $vars = {};
#    my $success = $list->subscribe_address( $email );
#    diag("Added $email: $success");
#}

