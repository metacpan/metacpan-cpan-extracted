#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use MVC::Neaf::Util qw(decode_json);

use MVC::Neaf;

get '/strict' => sub {
    my $req = shift;
    +{
        id   => $req->param( id => '\d+' ),
        sess => $req->get_cookie( sess => '\w+' ),
        name => $req->postfix,
        mult => [ $req->multi_param( mult => '\d+' ) ],
        url  => $req->url_param( url => '\d+' ),
    };
}, path_info_regex => '...', strict => 1;

my ($status, undef, $content) = neaf->run_test(
    '/strict/foo?id=42',
    cookie => { sess => 137 }
);
is $status, 200, "Happy case ok";
is_deeply decode_json( $content )
    , { name => 'foo', id => 42, sess => 137, mult => [], url => undef }
    , "Happy case param round-trip";

($status) = neaf->run_test(
    '/strict/foobar?id=42',
    cookie => { sess => 137 },
);
is $status, 404, "postfix regex failed (TODO 422 as well)";

($status) = neaf->run_test(
    '/strict/foo?id=x42',
    cookie => { sess => 137 },
);
is $status, 422, "param regex failed";

($status) = neaf->run_test(
    '/strict/foo?id=42',
    cookie => { sess => 'words with spaces' },
);
is $status, 422, "cookie regex failed";

($status) = neaf->run_test(
    '/strict/foo?id=42',
    cookie => { sess => 'words with spaces' },
);
is $status, 422, "cookie regex failed";

($status) = neaf->run_test(
    '/strict/foo?url=xxx',
    cookie => { sess => 'words with spaces' },
);
is $status, 422, "url_param regex failed";

($status) = neaf->run_test(
    '/strict/foo?mult=1&mutl=2&mult=none&mult=4',
    cookie => { sess => 'words with spaces' },
);
is $status, 422, "multi_param regex failed";

done_testing;

