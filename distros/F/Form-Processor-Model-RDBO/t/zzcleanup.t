use strict;
use Test::More tests => 1;

use lib 't/lib';

use NewDB;
my $db = NewDB->new();

$db->cleanup();

ok( !-f $db->dbname );
