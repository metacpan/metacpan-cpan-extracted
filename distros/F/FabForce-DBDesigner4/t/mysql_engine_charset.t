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
  
  my $file = $FindBin::Bin .'/test.xml';
  $designer->parsefile(xml => $file);
  
  my @creates = (qq~CREATE TABLE `Testtable` (
  column1 INTEGER NOT NULL AUTO_INCREMENT,
  col2 VARCHAR(255),
  PRIMARY KEY(column1)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

~);
  
  my $test = Dumper \@creates;
  my $check = Dumper [$designer->getSQL({type => 'mysql', sql_options => {engine => 'InnoDB', charset => 'utf8',}})];
  is($check, $test, 'check getSQL()');