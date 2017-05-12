#!/usr/bin/env perl
use Test::More;
use lib qw'lib t/lib';
use Git::Release;
use Git::Release::Config;
use Git::Release::Branch;
use File::Path qw(rmtree mkpath);
use GitTestUtils qw(create_repo mk_commit);

create_repo 'test_repo';

my $re = Git::Release->new;
ok $re;
diag 'Testing Path: ' . $re->repo->wc_path;

mk_commit $re, 'README', 'new changes';

ok( $re );
ok( $re->repo );
is( 'Git', ref( $re->repo ) );

ok $re->branch , 'got branch manager';

ok( $re->get_current_branch );
is( 'master', $re->get_current_branch->name );
ok( 'master', $re->get_current_branch->ref );

ok( $re->config );
ok( $re->config->repo , 'Repository object' );
is( 'Git' , ref( $re->config->repo ) , 'is Git');

{
    my $branch = Git::Release::Branch->new( ref => 'test', manager => $re );
    ok( $branch , 'branch ok' );

    is( $branch->name , 'test' , 'branch name' );

    $branch->create( from => 'master' );
    ok( $branch->is_local );

    my $new_name = $branch->move_to_ready;
    ok( $new_name , $new_name );
    $branch->delete;
}


{
    my $branch = Git::Release::Branch->new( ref => 'test', manager => $re );
    ok( $branch , 'branch ok' );
    is( $branch->name , 'test' , 'branch name' );
    $branch->create( from => 'master' );
    ok( $branch->is_local , 'branch created' );

    my $ok = $branch->move_to_ready;
    ok $ok;
    is( 'ready/test' , $branch->name , 'ready branch ok' );

    $ok = $branch->move_to_released;
    ok $ok;
    is( 'released/test' , $branch->name , 'released branch ok' );

    $branch->delete;
}

$re->gc;


chdir '..';
rmtree [ 'test_repo' ];

done_testing;
