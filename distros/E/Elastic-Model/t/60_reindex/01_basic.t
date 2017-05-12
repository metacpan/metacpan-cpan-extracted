#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;
use Test::Deep;
use Search::Elasticsearch;

use lib 't/lib';

our $es;
do 'es.pl';

use_ok 'MyApp' || print 'Bail out';

my $model = new_ok( 'MyApp', [ es => $es ], 'Model' );
ok my $ns = $model->namespace('myapp'), 'Got ns';

create_users($model);
isa_ok my $new = $ns->index('myapp4'), 'Elastic::Model::Index', 'New index';

# No opts
throws_ok sub { $new->reindex }, qr/No \(domain\)/, 'Missing domain';

# Domain reindex
ok $new->reindex('myapp'), 'Reindex domain myapp to myapp4';
compare_results(
    'Domain myapp reindexed to myapp4',
    { index => 'myapp' },
    { index => 'myapp4' }
);

ok $new->delete;

ok $new->reindex(
    'myapp',
    quiet     => 1,
    scan      => '1m',
    size      => 10,
    bulk_size => 50,
    ),
    'Args check';

done_testing;

#===================================
sub compare_results {
#===================================
    my ( $desc, $q1, $q2 ) = @_;

    $model->es->indices->refresh();

    my @r1 = map { delete $_->{_index}; $_ } @{
        $model->es->search(
            %$q1,
            body => {
                size   => 300,
                query  => { match_all => {} },
                'sort' => [ 'timestamp', '_uid' ],
            },
        )->{hits}{hits}
    };

    my @r2 = map { delete $_->{_index}; $_ } @{
        $model->es->search(
            %$q2,
            body => {
                size   => 300,
                query  => { match_all => {} },
                'sort' => [ 'timestamp', '_uid' ],
            },
        )->{hits}{hits}
    };

    cmp_deeply \@r1, \@r2, $desc;
}
