#!/usr/bin/env perl

use 5.10.0;
use Test::More tests => 8;
use HTML::FormHelpers qw/ :all /;
use Test::XPath;

{
    my $generated = button('foo');
    my $tx = Test::XPath->new( xml => $generated, is_html => 1 );

    $tx->ok('//input', 'Has input tag');
    $tx->ok('//input[@type="button"]', 'input tag is a button');
    $tx->ok('//input[@name="foo"]', 'input tag has name attr with value "foo"');
    $tx->ok('//input[@value="foo"]', 'input tag has value attr with value "foo"');
}

{

    my $generated = button('foo', 'bar');
    my $tx = Test::XPath->new( xml => $generated, is_html => 1 );

    $tx->ok('//input', 'Has input tag');
    $tx->ok('//input[@type="button"]', 'input tag is a button');
    $tx->ok('//input[@name="foo"]', 'input tag has name attr with value "foo"');
    $tx->ok('//input[@value="bar"]', 'input tag has value attr with value "bar"');
}
