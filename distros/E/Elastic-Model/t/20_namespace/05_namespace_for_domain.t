#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;

use lib 't/lib';

our $es;
do 'es.pl';

use_ok 'MyApp' || print 'Bail out';

my $model = new_ok( 'MyApp', [ es => $es ], 'Model' );
ok my $ns = $model->namespace('myapp1'), 'Got ns';

is $model->namespace_for_domain('myapp1')->name, 'myapp1',
    'Has default domain';
is $model->namespace_for_domain('myapp1_fixed')->name, 'myapp1',
    'Has fixed domain';
throws_ok sub { $model->namespace_for_domain('myapp2') }, qr/No namespace/,
    'Unknown domain';

for (qw(myapp2 myapp3 myapp4)) {
    ok $ns->index($_)->create, "Create index $_";
}

ok $ns->alias->to( 'myapp2', 'myapp3' ), 'Alias default to myapp2/3';
ok $ns->alias('myapp1_fixed')->to('myapp4'), 'Alias fixed to myapp4';

for (qw(myapp2 myapp3 myapp4)) {
    is $model->namespace_for_domain($_)->name, 'myapp1', "Has domain $_";
}

ok $ns->alias('myapp')->to('myapp2'), 'Alias myapp to myapp2';
throws_ok sub { $model->namespace_for_domain('myapp') }, qr/Cannot map/,
    'Overlapping domains';

$es->indices->delete( index => 'myapp*', ignore => 404 );

done_testing;

__END__
