use Test::More;
use DBI;
use HTML::DBTable;
use DBIx::DBSchema::Table;
use DBIx::DBSchema::Column;

my $reason = "You haven't patched DBIx::DBSchema. If you think to use Mysql datbase take a look to INSTALL file of this distribution and patch you DBIx::DBSchema modules";

my $column1 = new DBIx::DBSchema::Column ( {
           'name'    => 'column1',
           'type'    => 'varchar',
           'null'    => 'NOT NULL',
           'length'  => 64,
           'default' => ''
         } );

if ($column1->can('enum')) {
    plan tests => 5;
} else {
    plan skip_all => $reason
}

BEGIN { use_ok('HTML::DBTable') }



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
$pd->tblschema($tblschema);

$pd->appearances(['hidden','combo']);
ok($pd->html=~/select name="column2"/,'setting a combo field appearance');
$pd->enums({column2 => [0,1,2,3]});
ok($pd->html=~/value="3" >3/,'checking combo items hash_array');
$pd->enums({column2 => {0=>'zero',1=>'uno',2=>'due',3=>'tre'}});
ok($pd->html=~/value="3" >tre/,'checking combo items hash_hash');
$pd->enums([undef, [0,1,2,3]]);
ok($pd->html=~/value="3" >3/,'checking combo items array_array');
$pd->enums([undef,{0=>'zero',1=>'uno',2=>'due',3=>'tre'}]);
ok($pd->html=~/value="3" >tre/,'checking combo items array_hash');


