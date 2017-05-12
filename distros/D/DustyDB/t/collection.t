use strict;
use warnings;

=head1 NAME

collection.t - test of collections of records

=cut

use Test::More tests => 64;
use Test::Moose;
use_ok('DustyDB');

# Declare a model
package Thing1;
use DustyDB::Object;

has key name    => ( is => 'rw', isa => 'Str' );
has description => ( is => 'rw', isa => 'Str', predicate => 'has_description' );

# and another
package Thing2;
use DustyDB::Object;

has key name => ( is => 'rw', isa => 'Str' );
has thing1   => ( is => 'rw', isa => 'Thing1' );

package main;

my $db = DustyDB->new( path => 't/collection.db' );
ok($db, 'Loaded the database object');
isa_ok($db, 'DustyDB');

my $thing1 = $db->model('Thing1');
ok($thing1, 'Loaded the thing1 model object');
isa_ok($thing1, 'DustyDB::Model');

my $thing2 = $db->model('Thing2');
ok($thing2, 'Loaded the thing2 model object');
isa_ok($thing2, 'DustyDB::Model');

# Create some things
{
    $thing1->create( name => 'test1', description => 'a thing' );
    $thing1->create( name => 'test2', description => 'another thing' );
    $thing1->create( name => 'test3' );

    $thing2->create( name => 'test1', thing1 => $thing1->load('test1') );
    $thing2->create( name => 'test2', thing1 => $thing1->load('test2') );
    $thing2->create( name => 'test3' );
}

# Get a list of things
{
    my @thing1s = $thing1->all;
    is(scalar @thing1s, 3, 'we got 3 things');

    for my $one_thing1 (@thing1s) {
        isa_ok($one_thing1, 'Thing1');
    }
    
    is($thing1s[0]->name, 'test1', 'thing1 1 is test1');
    is($thing1s[1]->name, 'test2', 'thing1 2 is test2');
    is($thing1s[2]->name, 'test3', 'thing1 3 is test3');

    my @thing2s = $thing2->all;
    is(scalar @thing2s, 3, 'we got 3 things');

    for my $one_thing2 (@thing2s) {
        isa_ok($one_thing2, 'Thing2');
    }
    
    is($thing2s[0]->name, 'test1', 'thing2 1 is test1');
    ok($thing2s[0]->thing1, 'thing2 has a thing1');
    is($thing2s[0]->thing1->name, $thing1s[0]->name, 'thing2 matches thing1 test1');
    is($thing2s[1]->name, 'test2', 'thing2 2 is test2');
    ok($thing2s[1]->thing1, 'thing2 has a thing1');
    is($thing2s[1]->thing1->name, $thing1s[1]->name, 'thing2 matches thing1 test2');
    is($thing2s[2]->name, 'test3', 'thing2 3 is test3');
    ok(!$thing2s[2]->thing1, 'thing2 does not have a thing1');
}

# Get a iterator of things
{
    my $thing1s = $thing1->all;
    ok($thing1s, 'we got an iterator');
    isa_ok($thing1s, 'DustyDB::Collection');
    is($thing1s->count, 3, 'got 3 things again');
    is($thing1s->first->name, 'test1', 'first thing is test1');
    is($thing1s->last->name, 'test3', 'last thing is test3');
    
    is($thing1s->next->name, 'test1', 'next thing is test1');
    is($thing1s->next->name, 'test2', 'next thing is test2');
    is($thing1s->next->name, 'test3', 'next thing is test3');
    is($thing1s->next, undef, 'iterator end');
    is($thing1s->next->name, 'test1', 'iterator restart');

    my $thing2s = $thing2->all;
    ok($thing2s, 'we got an iterator');
    isa_ok($thing2s, 'DustyDB::Collection');
    is($thing2s->count, 3, 'got 3 things again');
    is($thing2s->first->name, 'test1', 'first thing is test1');
    is($thing2s->last->name, 'test3', 'last thing is test3');
    
    is($thing2s->next->name, 'test1', 'next thing is test1');
    is($thing2s->next->name, 'test2', 'next thing is test2');
    is($thing2s->next->name, 'test3', 'next thing is test3');
    is($thing2s->next, undef, 'iterator end');

    ok($thing2s->next->thing1, 'next thing2 has a thing1');
    ok($thing2s->next->thing1, 'next thing2 has a thing1');
    ok(!$thing2s->next->thing1, 'next thing2 does not have a thing1');
    is($thing2s->next, undef, 'iterator end');
    is($thing2s->next->name, 'test1', 'iterator restart');
}

# Try a filter in all()
{
    my $thing1s = $thing1->all( name => qr/[23]$/ );
    ok($thing1s, 'we got an iterator');
    isa_ok($thing1s, 'DustyDB::Collection');
    is($thing1s->count, 2, 'got 2 things this time');
    is($thing1s->next->name, 'test2', 'next thing is test2');
    is($thing1s->next->name, 'test3', 'next thing is test3');
}

# Try a filter with all->filter()
{
    my $thing1s = $thing1->all->filter( 'has_description' );
    ok($thing1s, 'we got an iterator');
    isa_ok($thing1s, 'DustyDB::Collection');
    is($thing1s->count, 2, 'got 2 things this time');
    is($thing1s->next->name, 'test1', 'next thing is test1');
    is($thing1s->next->name, 'test2', 'next thing is test2');
}

# Try a third filter with all_where()
{
    my $all_thing1s = $thing1->all;
    my $thing1s = $all_thing1s->filter( sub { $_->name eq 'test3' } );
    ok($thing1s, 'we got an iterator');
    isa_ok($thing1s, 'DustyDB::Collection');
    is($thing1s->count, 1, 'got 1 things this time');
    is($thing1s->next->name, 'test3', 'next thing is test3');
}

unlink 't/collection.db';
