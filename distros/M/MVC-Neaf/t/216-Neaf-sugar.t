#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

get  foo => sub {+{}}, -view => 'JS';
post bar => sub {+{}}, -view => 'JS';
get + post '/plus' => sub { +{-content => 'sugar='.$_[0]->method} };

neaf error => 404 => { -content => 'Second Foundation' };

my @re = neaf->run_test( '/foo?x=42' );
is ($re[0], 200, "request ok");
is ($re[2], '{}', "content ok");

@re = neaf->run_test( '/bar?x=42' );
is ($re[0], 405, "wrong method" );

@re = neaf->run_test( '/baz?x=42' );
is ($re[0], 404, "not found" );
is ($re[2], 'Second Foundation', "2nd foundation is not found" );

@re = neaf->run_test( '/plus?x=42' );
is ($re[0], 200, "postmodern GET request ok");
is ($re[2], 'sugar=GET', "postmodern content ok");

@re = neaf->run_test( '/plus?x=42', method => 'POST' );
is ($re[0], 200, "postmodern POST request ok");
is ($re[2], 'sugar=POST', "postmodern content ok");

@re = neaf->run_test( '/plus?x=42', method => 'PUT' );
is ($re[0], 405, "postmodern PUT request not ok");

done_testing;
