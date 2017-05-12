#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use JSON;

use MVC::Neaf::View;
use MVC::Neaf::View::TT;
use MVC::Neaf::View::JS;

my $tt = MVC::Neaf::View::TT->new(
    INCLUDE_PATH => ".",
    POST_CHOMP => 1,
);

is_deeply ( [$tt->render({})], [ '', 'text/plain' ], "Plain return if no tpl");
is_deeply ( [$tt->render( { -template => \"[% foo %]", foo => 42 } ) ]
    , [ 42, 'text/html' ], "TT as expected" );

my $js = MVC::Neaf::View::JS->new;
is_json ([ $js->render( { -template => "foo", code => sub { }, scalar => \"", x => "Y" } ) ]
    , {"x" => "Y", code => undef, scalar => undef }, "JSON render is safe");

is_deeply ([ $js->render( { -jsonp => "foo.bar" } ) ],
    , ['foo.bar({});', "application/javascript; charset=utf-8" ], "jsonp callback worked" );
is_deeply ([ $js->render( { -jsonp => 'alert("pwned!");foo.bar' } ) ],
    , ['{}', "application/json; charset=utf-8" ]
    , "jsonp exploit didn't work" );

my $plain = MVC::Neaf::View->new( on_render => sub { foo => 'text/plain' } );
is_deeply( [$plain->render( {} )], [ foo => 'text/plain' ], "callback in view");

done_testing;

sub is_json {
    my ($got, $exp, $note) = @_;

    is( $got->[1], 'application/json; charset=utf-8', "json ctype" );
    return is_deeply( decode_json( $got->[0] ), $exp, $note );
};

