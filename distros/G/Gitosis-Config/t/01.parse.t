#!/usr/bin/env perl 
use strict; 
use Test::More;

use Gitosis::Config;

my $file = 'ex/example.conf';

ok( my $gc = Gitosis::Config->new( file => $file ) );
is( $gc->gitweb, 'no' );
ok( my @groups = $gc->groups, 'has groups' );

for my $group (@groups) {
    ok( $group->{name},    qq'$group->{name} has name' );
    ok( $group->{members}, qq'$group->{name} has members' );
    isa_ok( $group, 'Gitosis::Config::Group', "$group->{name}" );
}

ok( my @repos = $gc->repos, 'has repos' );
for my $repo (@repos) {
#    isa_ok( $group, 'Gitosis::Config::Repo', 'got a Gitosis::Config::Repo' );
    ok( $repo->{name},  'repo has name' );
    ok( $repo->{owner}, 'repo has owner' );
}

ok(my $quux = $gc->find_group_by_name('quux'), 'found group by name');
is($quux->name, 'quux', 'group name correct');

done_testing;
