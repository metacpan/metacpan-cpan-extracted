use strict;
use warnings;

use Test::More tests => 1;

use Path::Class;
use Git::PurePerl;
use GitStore;

# init the test
my $directory = 't/test';
dir($directory)->rmtree;
my $gitobj = Git::PurePerl->init( directory => $directory );

my $gs = GitStore->new($directory);

$gs->set( 'alpha', 'a' );
$gs->set( 'beta', 'a' );

$gs->commit;

$gs->delete('alpha');

$gs->commit;

$gs->delete('beta');

$gs->commit;

pass "made it";


