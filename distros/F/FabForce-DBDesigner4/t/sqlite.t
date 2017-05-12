# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FabForce-DBDesigner4.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
use FindBin qw();
use FabForce::DBDesigner4;
use Data::Dumper;

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

  my $designer = FabForce::DBDesigner4->new();
  ok(ref $designer eq 'FabForce::DBDesigner4');
  
  my $file = $FindBin::Bin .'/test5.xml';
  $designer->parsefile(xml => $file);
  
  my @creates = (qq~CREATE TABLE `Testtable` (
  column1 INTEGER NOT NULL PRIMARY KEY,
  col2 VARCHAR(255)
);

~,
qq~CREATE TABLE `Testtable2` (
  column1 VARCHAR(255) NOT NULL,
  col2 VARCHAR(255),
  PRIMARY KEY(column1)
);

~,);
  
  my $test = Dumper \@creates;
  my $check = Dumper [$designer->getSQL({type => 'sqlite'})];
  is($check, $test, 'check getSQL()');
