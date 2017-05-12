#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;
use Test::Deep;
use Scalar::Util qw(refaddr);

use lib 't/lib';

our $es;
do 'es.pl';

use_ok 'MyApp' || print 'Bail out';

my $model = new_ok( 'MyApp', [ es => $es ], 'Model' );
isa_ok my $index = $model->namespace('myapp')->index, 'Elastic::Model::Index';
ok $index->create, 'Create index myapp';
isa_ok my $domain = $model->domain('myapp'), 'Elastic::Model::Domain';
isa_ok my $bulk = $model->bulk( size => 10 ), 'Elastic::Model::Bulk';

# no scope
my $u1 = $domain->new_doc( user => { id => 1, name => 'one' } );
$bulk->save($u1);
$bulk->commit;

# scope active
isa_ok my $scope = $model->new_scope, 'Elastic::Model::Scope';

my $u2 = $domain->new_doc( user => { id => 2, name => 'two' } );
$bulk->save($u2);
$bulk->commit;

ok refaddr($u1) ne refaddr( $domain->get( user => 1 ) ),
    'U1 scope not active';

is refaddr($u2), refaddr( $domain->get( user => 2 ) ), 'U2 scope active';

done_testing;

__END__
