#!perl

package TestObject;

use strict;
use warnings;

sub new {
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    return $self;
}

sub get_tan {
    return "4711";
}


package main;

use strict;
use warnings;

#open(STDERR, ">/tmp/STDERR.out");

use Test::More tests => 4;
use Finance::Bank::DE::NetBank;

my %config = (
        CUSTOMER_ID => "demo",        # Demo Login
        PASSWORD    => "",            # Demo does not require a password
        ACCOUNT     => "1234567",     # Demo Account Number (Kontonummer)
        );

my $account = Finance::Bank::DE::NetBank->new(%config);
#$account->Debug(1);


ok( defined($account->login()), 'login with offical demo login works');


# hash with TANS
#

my %tanhash;

for (my $i=0; $i <= 100; $i++) {
    $tanhash{$i} = sprintf("%04d", $i);
}

ok( defined($account->transfer(
                RECEIVER_NAME => "Bill Gates",
                RECEIVER_ACCOUNT => "999999",
                RECEIVER_BLZ => "99999999",
                RECEIVER_SAVE => 0,
                COMMENT_1 => "WINDOWS",
                COMMENT_2 => "LICENSES",
                AMOUNT => "00.01",
                TAN => \%tanhash)
           ), 'demo transfer (TAN HASH)' );


# hash with CALLBACK sub
#

sub callback {
    my $index = shift;
    return sprintf("%04d", $index);
}

ok( defined($account->transfer(
                RECEIVER_NAME => "Bill Gates",
                RECEIVER_ACCOUNT => "999999",
                RECEIVER_BLZ => "99999999",
                RECEIVER_SAVE => 0,
                COMMENT_1 => "WINDOWS",
                COMMENT_2 => "LICENSES",
                AMOUNT => "00.01",
                TAN => \&callback)
           ), 'demo transfer (CALLBACK)' );

my $object = new TestObject;
my $method = "get_tan";

ok( defined($account->transfer(
                RECEIVER_NAME => "Bill Gates",
                RECEIVER_ACCOUNT => "999999",
                RECEIVER_BLZ => "99999999",
                RECEIVER_SAVE => 0,
                COMMENT_1 => "WINDOWS",
                COMMENT_2 => "LICENSES",
                AMOUNT => "00.01",
                TAN => [$object, $method])
           ), 'demo transfer (Object/Method)' );





