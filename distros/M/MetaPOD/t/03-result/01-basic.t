use strict;
use warnings;
use Test::More tests => 2;

use MetaPOD::Result;

my $object = MetaPOD::Result->new();

$object->set_namespace('Example');
$object->set_inherits( 'A', 'B', 'C', 'C' );

is_deeply( [ sort $object->inherits ], [ 'A', 'B', 'C' ], 'set_inherits autodedups' );
$object->add_inherits( 'A', 'D' );
is_deeply( [ sort $object->inherits ], [ 'A', 'B', 'C', 'D' ], 'add_inherits autodedups' );
