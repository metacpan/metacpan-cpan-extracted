# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Finance::Currency::ParValueSeparate;
use Finance::Currency::ParValueSeparate::RMB;
$loaded = 1;
print "ok 1\n";

##################
use Data::Dumper;
my $pvs;

$pvs = new Finance::Currency::ParValueSeparate( currency => 'RMB' );
print Dumper($pvs);
$pvs = new Finance::Currency::ParValueSeparate( RMB => 317.34 );
print Dumper($pvs);
$pvs = new Finance::Currency::ParValueSeparate( RMB => ['317.34','512.14'] );
print Dumper($pvs);
$pvs = new Finance::Currency::ParValueSeparate::RMB( 317.34, 512.14 );
print Dumper($pvs);
$pvs = new Finance::Currency::ParValueSeparate::RMB( ['317.34','512.14'] );
print Dumper($pvs);

######################################################
print "-" x 80, "\n";
my @amount = $pvs->amount;
print "amount as array: \n", Dumper(@amount);
my $amount = $pvs->amount;
print "amount as array ref: \n", Dumper($amount);

######################################################
print "-" x 80, "\n";
$pvs->with_dollar(qw(20 5));
print "with dollor: \n", Dumper($pvs);
$pvs->with_dollar([20,10,34]);
print "with dollor: \n", Dumper($pvs->with_dollar);
print "without dollor: \n", Dumper($pvs->without_dollar);
######################################################
print "-" x 80, "\n";
$pvs->without_dollar(qw(20 5));
print "without dollor: \n", Dumper($pvs);
$pvs->without_dollar([20,10,34]);
print "with dollor: \n", Dumper($pvs->with_dollar);
print "without dollor: \n", Dumper($pvs->without_dollar);
######################################################
print "-" x 80, "\n";
print "only_dollor set 1: ", $pvs->only_dollar(1),"\n";
print "only_dollor set 0: ", $pvs->only_dollar(0),"\n";
print "only_dollor return: ", $pvs->only_dollar(),"\n";
######################################################
print "-" x 80, "\n";
print "amount 314.65\n";
$pvs->parse(314.65);
map { print "dollar parvalue \$$_: ", $pvs->number_of_dollar($_), "\n" } $pvs->dollar_parvalues;
map { print "cent parvalue \$$_: ", $pvs->number_of_cent($_), "\n" } $pvs->cent_parvalues;
######################################################
print "-" x 80, "\n";
print "amount 314.65,45.23\n";
$pvs->parse(314.65,45.23);
map { print "dollar parvalue \$$_: ", $pvs->number_of_dollar($_), "\n" } $pvs->dollar_parvalues;
map { print "cent parvalue \$$_: ", $pvs->number_of_cent($_), "\n" } $pvs->cent_parvalues;
######################################################
print "-" x 80, "\n";
print "amount 573\n";
$pvs->parse(573);
map { print "dollar parvalue \$$_: ", $pvs->number_of_dollar($_), "\n" } $pvs->dollar_parvalues;
map { print "cent parvalue \$$_: ", $pvs->number_of_cent($_), "\n" } $pvs->cent_parvalues;
######################################################
print "-" x 80, "\n";
print "amount 573 x 10 \n";
$pvs->parse([573,573,573,573,573,573,573,573,573,573]);
map { print "dollar parvalue \$$_: ", $pvs->number_of_dollar($_), "\n" } $pvs->dollar_parvalues;
map { print "cent parvalue \$$_: ", $pvs->number_of_cent($_), "\n" } $pvs->cent_parvalues;
