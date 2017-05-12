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

use_ok 'Nested' || print 'Bail out';

my $model = new_ok( 'Nested', [ es => $es ], 'Model' );
ok my $ns = $model->namespace('myapp'), 'Got ns';

ok $ns->index('myapp')->create, 'Create index myapp';

isa_ok my $domain = $model->domain('myapp'), 'Elastic::Model::Domain',
    'Got domain myapp';

isa_ok my $doc
    = $domain->create(
    multiuser => { entry => [ { first => 'john', last => 'smith' } ] } ),
    'MyApp::MultiUser', 'Create doc';

is $doc->has_changed, '', 'Has not changed';
ok $doc->entry( [ { first => 'larry', last => 'wall' } ] ), 'Change doc';
is $doc->has_changed, 1, 'Has changed';
ok $doc->entry( [ { first => 'john', last => 'smith' } ] ), 'Change doc back';
is $doc->has_changed, '', 'Has not changed';

## DONE ##

done_testing;

__END__
