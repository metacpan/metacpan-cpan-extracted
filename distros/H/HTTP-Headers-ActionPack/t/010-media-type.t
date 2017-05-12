#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTTP::Headers::ActionPack::MediaType');
}

sub test_media_type {
    my $media_type = shift;

    isa_ok($media_type, 'HTTP::Headers::ActionPack::MediaType');

    is($media_type->type, 'application/xml', '... got the right type');
    is_deeply(
        $media_type->params,
        { 'charset' => 'UTF-8' },
        '... got the right params'
    );

    is($media_type->major, 'application', '... got the right major portion');
    is($media_type->minor, 'xml', '... got the right minor portion');

    is($media_type->as_string, 'application/xml; charset="UTF-8"', '... the string representation');

    my $media_type_2 = HTTP::Headers::ActionPack::MediaType->new('application/xml', => ( 'charset' => 'UTF-8' ));
    isa_ok($media_type_2, 'HTTP::Headers::ActionPack::MediaType');
    is($media_type_2->as_string, 'application/xml; charset="UTF-8"', '... the string representation');

    ok($media_type->equals( $media_type_2 ), '... these types are equal');
    ok($media_type->equals('application/xml; charset=UTF-8'), '... these types are equal');

    ok(!$media_type->matches_all, '... this is not a matches_all type');

    ok($media_type->exact_match('application/xml;charset=UTF-8'), '... these types are an exact match');
    ok($media_type->exact_match('application/*;charset=UTF-8'), '... these types are an exact match');
    ok($media_type->exact_match('*/*;charset=UTF-8'), '... these types are an exact match');

    ok(!$media_type->exact_match('application/json;charset=UTF-8'), '... these types are not an exact match');
    ok(!$media_type->exact_match('application/xml;charset=Latin-1'), '... these types are not an exact match');

    ok($media_type->match('application/xml'), '... these types are a match');

    ok(!$media_type->match('application/xml;charset=UTF-8;version=1'), '... these types are not a match');
    ok(!$media_type->match('application/*;charset=UTF-8;version=1'), '... these types are not a match');
    ok(!$media_type->match('*/*;charset=UTF-8;version=1'), '... these types are a match');
    ok(!$media_type->match('application/xml;charset=Latin-1;version=1'), '... these types are not a match');
    ok(!$media_type->match('application/json;charset=UTF-8;version=1'), '... these types are not a match');
}

test_media_type(
    HTTP::Headers::ActionPack::MediaType->new_from_string('application/xml;charset=UTF-8')
);

test_media_type(
    HTTP::Headers::ActionPack::MediaType->new('application/xml', 'charset' => 'UTF-8')
);

{
    my $matches_all = HTTP::Headers::ActionPack::MediaType->new_from_string('*/*');

    is($matches_all->type, '*/*', '... got the right type');
    is_deeply(
        $matches_all->params,
        {},
        '... got the right params'
    );

    is($matches_all->as_string, '*/*', '... the string representation');

    ok($matches_all->matches_all, '... this type does match all');
}

{
    my $multiline = HTTP::Headers::ActionPack::MediaType->new_from_string(q[multipart/form-data;
boundary=----------------------------2c46a7bec2b9]);

    is($multiline->type, 'multipart/form-data', '... got the right type');
    is_deeply(
        $multiline->params,
        { 'boundary' => '----------------------------2c46a7bec2b9' },
        '... got the right params'
    );

    is($multiline->as_string, 'multipart/form-data; boundary="----------------------------2c46a7bec2b9"', '... the string representation');
}

# test multiple params ...
{
    my $mt = HTTP::Headers::ActionPack::MediaType->new_from_string('application/json;v= 3;foo=bar');

    is($mt->type, 'application/json', '... got the right type');
    is_deeply(
        $mt->params,
        { v => 3, foo => 'bar' },
        '... got the right params'
    );

    is($mt->as_string, 'application/json; v="3"; foo="bar"', '... got the right string representation');
}

# test a lot of params ...
{
    my $mt = HTTP::Headers::ActionPack::MediaType->new_from_string('application/json; v=3;foo=bar;q=0.25;testing=123');

    is($mt->type, 'application/json', '... got the right type');
    is_deeply(
        $mt->params,
        { v => 3, foo => 'bar', q => 0.25, testing => 123 },
        '... got the right params'
    );

    is($mt->as_string, 'application/json; v="3"; foo="bar"; q="0.25"; testing="123"', '... got the right string representation');
}

# test with quoted strings
{
    my $mt = HTTP::Headers::ActionPack::MediaType->new_from_string('application/json; v=3; foo=bar; q="0.25"; testing="1,23"');

    is($mt->type, 'application/json', '... got the right type');
    is_deeply(
        $mt->params,
        { v => 3, foo => 'bar', q => 0.25, testing => '1,23' },
        '... got the right params'
    );

    is($mt->as_string, 'application/json; v="3"; foo="bar"; q="0.25"; testing="1,23"', '... got the right string representation');
}
{
    my $mt = HTTP::Headers::ActionPack::MediaType->new_from_string('application/json; v=3; foo=bar; q=0.25; testing="1;23"');

    is($mt->type, 'application/json', '... got the right type');
    is_deeply(
        $mt->params,
        { v => 3, foo => 'bar', q => 0.25, testing => '1;23' },
        '... got the right params'
    );

    is($mt->as_string, 'application/json; v="3"; foo="bar"; q="0.25"; testing="1;23"', '... got the right string representation');
}
{
    my $mt = HTTP::Headers::ActionPack::MediaType->new_from_string('application/json; v=3; foo=bar; q=0.25; testing="12\"3\""');

    is($mt->type, 'application/json', '... got the right type');
    is_deeply(
        $mt->params,
        { v => 3, foo => 'bar', q => 0.25, testing => '12"3"' },
        '... got the right params'
    );

    is($mt->as_string, 'application/json; v="3"; foo="bar"; q="0.25"; testing="12\"3\""', '... got the right string representation');
}

done_testing;


