#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN { plan tests => 1; }

use GoogleIDToken::Validator;

my $validator = GoogleIDToken::Validator->new(
    web_client_id => 'test',
    app_client_ids => [ 'test' ]
);

ok( $validator );
