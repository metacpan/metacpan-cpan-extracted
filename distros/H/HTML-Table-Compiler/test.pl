# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
use Data::Dumper;
BEGIN { plan tests => 5 };
use_ok("HTML::Table::Compiler");

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.


my $table = HTML::Table::Compiler->new(2, 3);
$table->autoGrow(1);
ok($table && $table->isa("HTML::Table"));
my $table_data = $table->compile([(1..10)]);

ok($table_data && ref $table_data);

ok($table->getTableCols == 3);
ok($table->getTableRows == 4 );
