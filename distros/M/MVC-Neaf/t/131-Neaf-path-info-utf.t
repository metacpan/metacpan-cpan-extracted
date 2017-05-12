#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use URI::Escape qw(uri_escape uri_unescape);

use MVC::Neaf;
my $app = MVC::Neaf->new;

$SIG{__DIE__} = \&Carp::confess;

$app->route( "/foo" => sub {
    return { -content => $_[0]->path_info }
}, path_info_regex => '.' );
$app->route( "/bar" => sub {
    return { -content => $_[0]->path_info }
}, path_info_regex => '\w+' );

my  ($status, $head, $content) = $app->run_test( '/foo/%25' );
is ($status, 200, "ok returned");
is ($content, '%', "data round-trip" );

    ($status, $head, $content) = $app->run_test( '/foo/%C2%A9' ); # &copy; sign
is ($status, 200, "ok returned");
note "Content was: $content";

    ($status, $head, $content) = $app->run_test( '/foo/%C2' );
        # &copy; sign, truncated

is ($status, 200, "ok returned");

note "NEGATIVE";

    ($status, $head, $content) = $app->run_test( '/foo/%%' );

is ($status, 404, "No path info match = not found");

note "ALPHANUMERIC";

    ($status, $head, $content) = $app->run_test( '/bar/%D0%98%D0%90%D0%AF' );

is ($status, 200, "\\w+ is ok with cyrillic" );

note "Content must look like mirror image of RAN: $content";

done_testing;
