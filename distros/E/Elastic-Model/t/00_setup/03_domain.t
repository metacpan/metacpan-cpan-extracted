#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Moose;

use lib 't/lib';

our $es;
do 'es.pl';

use_ok 'Foo' || print 'Bail out';

my $model = new_ok( 'Foo', [ es => $es ], 'Model' );
note 'Domain';

isa_ok $model->domain('foo'), 'Elastic::Model::Domain', 'Domain foo';
isa_ok $model->domain('aaa'), 'Elastic::Model::Domain', 'Domain aaa';
isa_ok $model->domain('bbb'), 'Elastic::Model::Domain', 'Domain bbb';

done_testing;

__END__

