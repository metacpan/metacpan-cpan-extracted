#!/usr/bin/env perl
use Test::More;
use lib qw'lib t/lib';
use Git::Release;
use Git::Release::Config;
use Git::Release::Branch;
use File::Path qw(rmtree mkpath);
use GitTestUtils qw(create_repo mk_commit);

# create_repo 'test_repo';

my $re = Git::Release->new;
ok $re;
# mk_commit $re, 'README', 'root commit';

ok $re->repo , 'get Git repo object';
ok $re->directory , 'get directory';
ok $re->branch , 'got branch manager';
ok $re->remote , 'got remote manager';
ok $re->remote->all , 'got remotes';

{
    my @remotes = $re->remote->all;
    ok @remotes, "got remotes";
    for my $r ( @remotes ) {
        ok $r;
        my $info = $r->info;
        ok $info->{tracking};
        is $info->{tracking}->{master}, 'remotes/origin/master';
    }
}

{
    my %list = $re->tracking_list;
    for my $local_ref ( keys %list ) {
        my $branch = $re->branch->new_branch( ref => $local_ref , tracking_ref => $list{ $local_ref } );
        ok $branch;
        ok $branch->name;
        ok $branch->ref;
        ok $branch->tracking_ref;
    }
}



my @branches = $re->branch->remote_branches;
ok @branches , 'got branches';
for my $b ( @branches ) {
    is 'Git::Release::Branch', ref $b;
    ok $b->remote, $b->remote;
    ok $b->is_remote , 'is remote';
    like $b->remote, qr/origin|github/;
}

my @branches = $re->branch->local_branches;
ok @branches;
for my $b ( @branches ) {
    is 'Git::Release::Branch', ref $b;
    ok $b->is_local, 'is local';
}


diag "test local branch finder";
{
    my $local;
    $local = $re->branch->find_local_branches( 'master' );
    is ref($local),'Git::Release::Branch';

    ($local) = $re->branch->find_local_branches( 'master' );
    is ref($local),'Git::Release::Branch';
}

diag "test remote branch finder";
{
    my $b;
    $b = $re->branch->find_remote_branches( 'master' );
    is ref($b),'Git::Release::Branch';

    ($b) = $re->branch->find_remote_branches( 'master' );
    is ref($b),'Git::Release::Branch';
    ok $b->is_remote;
}


{
    my $current = $re->branch->current;
    ok $current;
    is ref($current),'Git::Release::Branch';
    ok $current->name;
    ok $current->ref;
}

{
    # create ready branch
    my $master = $re->branch->new_branch('master');
    my $develop = $re->branch->new_branch( 'test_develop' )->create( from => 'master' );
    ok $develop , 'develop branch is created';
    $develop->checkout;
    is $re->branch->current->name, 'test_develop';
    $master->checkout;
    is $re->branch->current->name, 'master';

    $develop->push('origin');
    $develop->delete( remote => 'origin' );
    $develop->delete( local => 1 );
    ok $develop->is_deleted, 'is deleted';
}

{
    my $master = $re->branch->new_branch('master');
    ok $master ,'got master';

    my $foo = $re->branch->new_branch( 'feature/foo' )->create( from => 'master' );
    ok $foo, 'got foo branch';
    is $foo->prefix, 'feature',   'prefix = feature';
    is $foo->name, 'feature/foo', 'name   = feature/foo';
    is $foo->ref, 'feature/foo',  'ref    = feature/foo';

    $foo->prepend_prefix('ready');
    is $foo->prefix , 'ready'              , 'prefix = ready';
    is $foo->name   , 'ready/feature/foo'  , 'name = ready/feature/foo';
    is $foo->ref    , 'ready/feature/foo'  , 'ref  = ready/feature/foo';
    $foo->delete;
};

done_testing;
