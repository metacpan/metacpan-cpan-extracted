#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

neaf->route( "/" => sub {
    my $req = shift;
    return {
        -content => $req->path_info(),
    };
}, path_info_regex => '.*' );

my $psgi = neaf->run;

my $reply = $psgi->( { REQUEST_URI => "/%C2%A9", } );

note explain $reply;

my ($status, $head, $content) = @$reply;
ok (!(@$head % 2), "headers are even");

$content = join "", @$content;
my %head_hash = @$head;
is (length $content, $head_hash{'Content-Length'}
    , "Content-Length == real length");
is ($head_hash{'Content-Type'}, 'text/plain; charset=utf-8'
    , "Binary autodetected");

# test 2 - plain
$reply = $psgi->( { REQUEST_URI => "/foobared", } );

($status, $head, $content) = @$reply;
ok (!(@$head % 2), "headers are even (2)");

$content = join "", @$content;
%head_hash = @$head;
is (length $content, $head_hash{'Content-Length'}
    , "Content-Length == real length");
is ($head_hash{'Content-Type'}, 'text/plain; charset=utf-8'
    , "Ascii autodetected");

done_testing;

