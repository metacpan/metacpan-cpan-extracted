#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use MVC::Neaf::Util qw(decode_json);

use MVC::Neaf;

neaf pre_render => sub { $_[0]->reply->{id} = $_[0]->id };

neaf helper => make_id => sub { "one" } => path => '/foo';

neaf helper => make_id => sub { "two" } => path => '/foo/bar';

get '/foo/baz' => sub { +{} };
get '/foo/bar/baz' => sub { +{} };
get '/baz' => sub { +{} };

my ($status, $content);

($status, undef, $content) = neaf->run_test( '/baz' );
$content = decode_json( $content );
like $content->{id}, qr#......#, "id outside helper area unaffected";
note "id=", $content->{id};

($status, undef, $content) = neaf->run_test( '/foo/baz' );
$content = decode_json( $content );
is $content->{id}, 'one', "id redefined";

($status, undef, $content) = neaf->run_test( '/foo/bar/baz' );
$content = decode_json( $content );
is $content->{id}, 'two', "id redefined in subpath";

done_testing;
