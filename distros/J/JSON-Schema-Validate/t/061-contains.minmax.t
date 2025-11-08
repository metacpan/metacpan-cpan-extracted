#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use lib './lib';
use open ':std' => 'utf8';
use JSON;
use JSON::Schema::Validate;

my $schema = {
    type => 'array',
    contains => { type => 'integer', minimum => 10 },
    minContains => 2,
    maxContains => 3,
};

my $js = JSON::Schema::Validate->new( $schema );

ok(  $js->validate([ 10, 11 ]),                'exactly 2 matches (min ok)' ) or diag( $js->error );
ok(  $js->validate([ 5, 10, 12 ]),             '2 matches with extra noise' ) or diag( $js->error );
ok(  $js->validate([ 10, 12, 100 ]),           'exactly 3 matches (max ok)' ) or diag( $js->error );
ok( !$js->validate([ 10 ]),                    'fails: only 1 match (< minContains)' );
ok( !$js->validate([ 10, 12, 100, 1000 ]),     'fails: 4 matches (> maxContains)' );

done_testing;

__END__
