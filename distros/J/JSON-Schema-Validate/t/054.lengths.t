#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use lib './lib';
use open ':std' => 'utf8';
use JSON;
use JSON::Schema::Validate;

# Testing 'minLength' and 'maxLength'
my $js = JSON::Schema::Validate->new({
    type => 'object',
    properties =>
    {
        username =>
        {
            minLength => 1,
            maxLength => 64,
            required => 1
        },
        password =>
        {
            minLength => 6,
            required => 1
        },
    },
});

ok(     $js->validate({ username => 'abc', password => 'abcdef' }) );
ok(     $js->validate({ username => 'abc', password => 'abcdefgh' }) );
ok( not $js->validate({ username => 'abc', password => 'abcde' }) );
ok( not $js->validate({ username => 'abc' }) );
ok( not $js->validate({ password => 'abcdefgh' }) );
ok( not $js->validate({ username => '', password => 'abcdefgh' }) );
ok( not $js->validate({ username => ('a' x 65), password => 'abcdefgh' }) );

done_testing;

__END__

