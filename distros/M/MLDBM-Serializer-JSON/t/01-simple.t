#!perl

use Test::More;

use MLDBM qw(SDBM_File JSON);
use Fcntl;
use File::Path;
use File::Spec;
use Cwd;

my $dir = File::Spec->catdir( getcwd(), 'test_output' );
my $fn = File::Spec->catfile( $dir, 'testdb' );

rmtree $dir;
END { rmtree $dir }
mkpath $dir;

my %db;
my $dbm = tie %db, 'MLDBM', $fn, O_RDWR | O_CREAT | O_TRUNC, 0666;

$db{foo} = 'bar';
$db{life} = 42;
$db{more} = [ qw(Perl rocks) ];
$db{rocks} = {
    DBI => [ 'Tim Bunce', 'Martin Evans', 'H. Merijn Brand', 'me?' ],
    Soccer => [ qw(Spain Netherland Germany) ],
};

cmp_ok( $db{foo}, 'eq', 'bar', 'foo' );
cmp_ok( $db{life}, '==', 42, 'life' );
is_deeply( $db{more}, [ qw(Perl rocks) ], 'more ...' );
is_deeply( $db{rocks}, {
    DBI => [ 'Tim Bunce', 'Martin Evans', 'H. Merijn Brand', 'me?' ],
    Soccer => [ qw(Spain Netherland Germany) ],
});

done_testing();
