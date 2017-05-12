use strict;
use warnings;

use Test::More tests => 4;

use GitStore;
use Path::Class;
use Git::PurePerl;

my $dir = './t/test';
dir($dir)->rmtree;

my $gitobj = Git::PurePerl->init( directory => $dir );

my $gs = GitStore->new( repo => $dir);

$gs->set( 'foo' => 'bar' );

$gs = GitStore->new( repo => $dir, autocommit => 1);

is $gs->get('foo') => undef, 'not auto-commited';

$gs->set( 'foo' => 'bar' );

{
    my $gs = GitStore->new( repo => $dir );

    is $gs->get('foo') => 'bar', 'auto-commited';

    $gs->delete('foo');
}

{
    my $gs = GitStore->new( repo => $dir, autocommit => 1 );

    is $gs->get('foo') => 'bar', 'delete not auto-commited';

    $gs->delete('foo');
}

{
    my $gs = GitStore->new( repo => $dir, autocommit => 1 );

    is $gs->get('foo') => undef, 'delete auto-commited';
}
