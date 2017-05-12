use strict;
use warnings;

use Test::More tests => 1;

use Git::PurePerl;
use Path::Class;
use GitStore;
use FindBin qw/$Bin/;

# init the test
my $directory = "$Bin/test";
dir($directory)->rmtree;
my $gitobj = Git::PurePerl->init( directory => $directory );

my $gs = GitStore->new($directory);

for ( 1..3 ) {
    $gs->set( 'foo' => 'blah' );
    $gs->commit( $_ );
}

for ( 1..3 ) {
    $gs->set( 'foo' => 'blah' );
    $gs->commit( 'the same' );
}

is $gs->history('foo') => 1, "only one commit that matters";
