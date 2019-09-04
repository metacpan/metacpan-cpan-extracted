use Test::More tests => 12;
use Test::Exception;

use strict;
use warnings;
use File::Spec;

use FindBin;

use DBI;
use Geoffrey;

require_ok('FindBin');
use_ok 'FindBin';

require_ok('DBI');
use_ok 'DBI';

require_ok('Geoffrey::Converter::SQLite');
use_ok 'Geoffrey::Converter::SQLite';

my $converter = Geoffrey::Converter::SQLite->new();
dies_ok { $converter->check_version('3.0') } 'underneath min version expecting to die';
is( $converter->check_version('3.7'), 1, 'min version check' );
is( $converter->check_version('3.9'), 1, 'min version check' );

my $s_filepath = '.tmp.sqlite';
my $dbh        = DBI->connect( "dbi:SQLite:database=$s_filepath", { PrintError => 0, RaiseError => 1 } );
my $object     = new_ok( 'Geoffrey' => [ dbh => $dbh ] ) or plan skip_all => "";
throws_ok { $object->read( File::Spec->catfile( $FindBin::Bin, 'data', 'changelog' ) ) }
'Geoffrey::Exception::NotSupportedException::Column', 'Not supportet thrown';

throws_ok { $converter->index->drop() } 'Geoffrey::Exception::RequiredValue::IndexName', 'Drop index needs a name';

$object->disconnect();
