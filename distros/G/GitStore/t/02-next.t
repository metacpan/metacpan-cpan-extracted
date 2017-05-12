#!perl

use Test::More tests => 4;
use FindBin qw/$Bin/;
use GitStore;
use Path::Class;

use lib 't/lib';
use Utils;

my $directory;

{ package Foo; use Moose; has x => ( is => 'ro' ); }

my $foo = Foo->new( x => 'y' );

{
    my $gs = new_gitstore();
    $directory = $gs->repo;

    $gs->set("committed.txt", 'Yes');
    $gs->set("gitobj.txt", $foo );
    $gs->commit;
    $gs->set("not_committed.txt", 'No');
}

my $gs = GitStore->new($directory);

is $gs->get("committed.txt") => 'Yes', 'was commited';
is $gs->get("not_committed.txt") => undef, 'was not';

subtest "objects are preserved" => sub {
    my $gitobj = $gs->get("gitobj.txt");
    isa_ok $gitobj => 'Foo';
    is $gitobj->x, $foo->x;
};

subtest 'delete across instances' => sub {
    {
        my $gs = GitStore->new($directory);
        $gs->delete('commited.txt');
        is $gs->get('commited.txt') => undef, 'file is gone';
    }
    {
        my $gs = GitStore->new($directory);
        is $gs->get('commited.txt') => undef, 'file is really gone';
    }
};
