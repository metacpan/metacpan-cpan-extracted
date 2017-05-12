use DBI;
use HTML::DBTable;
use DBIx::DBSchema::Table;
use DBIx::DBSchema::Column;

use Test::More tests => 11;
BEGIN { use_ok('HTML::DBTable') }



my $column1 = new DBIx::DBSchema::Column ( {
           'name'    => 'column1',
           'type'    => 'varchar',
           'null'    => 'NOT NULL',
           'length'  => 64,
           'default' => ''
         } );
my $column2 = new DBIx::DBSchema::Column ( {
           'name'    => 'column2',
           'type'    => 'int',
           'null'    => 'NOT NULL',
           'default' => ''
         } );

my $column3 = new DBIx::DBSchema::Column ( {
           'name'    => 'column3',
           'type'    => 'Date',
           'null'    => 'NULL',
           'default' => ''
         } );

my $tblschema =  new DBIx::DBSchema::Table (
           				"DBTable_test",
						"column1",
						undef,
						undef,
						($column1,$column2,$column3)
				);

my $pd = new HTML::DBTable();
isa_ok( $pd,'HTML::DBTable', 'testing object ISA');
isa_ok( $pd->tblschema($tblschema),
				'DBIx::DBSchema::Table','testing DBIx::DBSchema::Table usage');
ok($pd->html=~/column1/m,'printing html output');
$item = {column1 => 'test1',column2=>'1',column3=>'2003-01-01'};
ok($pd->html=~/column1/m,'printing html output');
ok($pd->html(values=>$item)=~/2003\-01\-01/m,'printing html output with values');

$pd->labels(['The column1','The column2','The column3']);
ok($pd->html=~/The column2/m,'configuring labels via arrayref');
$pd->labels({column1=>'The column1'});
ok($pd->html=~/The column1/m,'configuring labels via hasref');
$pd->appearances({column1 => 'hidden'});
ok($pd->html=~/type="HIDDEN" name="column1"/,'test appearances setting an hidden field');
$pd->appearances(['hidden']);
ok($pd->html=~/type="HIDDEN" name="column1"/,'the same with positional item');
$pd->strip_tablename(0);
ok($pd->html=~/DBTable_test\./,'don\'t strip table name');
