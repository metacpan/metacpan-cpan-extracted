# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FabForce-DBDesigner4.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 11;
use FindBin qw();
use FabForce::DBDesigner4;
use Data::Dumper;

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $designer = FabForce::DBDesigner4->new();
ok(ref $designer eq 'FabForce::DBDesigner4');

my $file = $FindBin::Bin .'/test2.xml';
$designer->parsefile(xml => $file);

my @creates = (qq~CREATE TABLE `test2` (
  col1 INTEGER NOT NULL AUTOINCREMENT,
  col2 INTEGER DEFAULT 0,
  col3 VARCHAR(255) DEFAULT 'default',
  PRIMARY KEY(col1)
);

~);

my ($table) = $designer->getTables;
my @details = @{ $table->column_details || [] };

is $details[0]->{PrimaryKey}, 1, 'col1 - PK';
is $details[0]->{NotNull}, 1, 'col1 - NN';
is $details[0]->{AutoInc}, 1, 'col1 - AI';

is $details[1]->{PrimaryKey}, 0, 'col2 - PK';
is $details[1]->{NotNull}, 0, 'col2 - NN';
is $details[1]->{AutoInc}, 0, 'col2 - AI';

is $details[2]->{PrimaryKey}, 0, 'col3 - PK';
is $details[2]->{NotNull}, 0, 'col3 - NN';
is $details[2]->{AutoInc}, 0, 'col3 - AI';
