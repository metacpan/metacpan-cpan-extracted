#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;
use Test::Deep;

use lib 't/lib';

our $es;
do 'es.pl';

use_ok 'MyApp' || print 'Bail out';

my $model = new_ok( 'MyApp', [ es => $es ], 'Model' );
ok my $ns = $model->namespace('myapp'), 'Got ns';

# Index a post per user into just myapp3
my @users  = create_users($model);
my $domain = $model->domain('myapp3');
my $i      = 200;
for my $user (@users) {
    $domain->create( post =>
            { id => $i++, title => 'Post by ' . $user->name, user => $user }
    );
}

$ns->index('myapp')->refresh;

is $domain->view( type => 'post' )->total, 196,
    'Indexed post per user to myapp3';

# Reindex myapp2 and myapp3 to myapp4
isa_ok my $new = $ns->index('myapp4'), 'Elastic::Model::Index', 'New index';
ok $new->reindex('myapp'), 'Reindexed myapp to myapp4';
$new->refresh;

cmp_deeply
    index_count( index => 'myapp4' ),
    { myapp4 => 196 },
    'Post.user UIDs reset to myapp4';

cmp_deeply
    index_count( index => 'myapp' ),
    { myapp2 => 131, myapp3 => 65 },
    'Post.user UIDs in myapp untouched';

$new->delete;

# Reindex just myapp3 to myapp4
ok $new->reindex('myapp3'), 'Reindexed myapp3 to myapp4';
$ns->index('myapp3')->refresh;
$new->refresh;

cmp_deeply
    index_count( index => 'myapp3' ),
    { myapp3 => 65, myapp2 => 131 },
    'myapp3 UIDs unchanged';

cmp_deeply
    index_count( index => 'myapp4' ),
    { myapp4 => 65, myapp2 => 131 },
    'myapp4 UIDs updated';

# Reindex just myapp2 to myapp4
$new->delete;
ok $new->reindex('myapp2'), 'Reindexed myapp2 to myapp4';
$ns->index('myapp3')->refresh;
$new->refresh;

cmp_deeply
    index_count( index => 'myapp3' ),
    { myapp3 => 65, myapp4 => 131 },
    'myapp3 UIDs updated';

cmp_deeply
    index_count( index => 'myapp4' ),
    {},
    'myapp4 has no UIDs';

done_testing;

#===================================
sub index_count {
#===================================
    my $terms = $model->es->search(
        @_,
        size => 0,
        body => {
            facets => { index => { terms => { field => 'user.uid.index' } } }
        }
    )->{facets}{index}{terms};
    return +{ map { $_->{term} => $_->{count} } @$terms };

}
