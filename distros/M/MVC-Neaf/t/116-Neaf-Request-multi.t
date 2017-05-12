#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use IO::Handle;

use MVC::Neaf::Request::PSGI;

my $req = MVC::Neaf::Request::PSGI->new( env => {
        REQUEST_METHOD => 'GET',
        QUERY_STRING   => 'foo=42&foo=137',
    } );

is ( $req->param( foo => '\d+' ), 137, "Second value if single param" );
is_deeply ( [$req->multi_param( foo => '\d+' )], [ 42, 137 ]
    , "Multi param happy case" );
is_deeply ( [$req->multi_param( foo => '\d\d' )], []
    , "Mismatch = no go" );

# prepare fake post body
my $fakedata = 'foo=42&foo=137';
open (my $fd, "<", \$fakedata);
my $io = IO::Handle->new_from_fd( $fd, '<' );

    $req = MVC::Neaf::Request::PSGI->new( env => {
        REQUEST_METHOD => 'POST',
        QUERY_STRING => 'foo=1',
        CONTENT_TYPE => 'application/x-www-form-urlencoded',
        CONTENT_LENGTH => length $fakedata,
        'psgi.input' => $io,
    } );

is ( $req->param( foo => '\d+' ), 137, "Second value if single param" );
is_deeply ( [$req->multi_param( foo => '\d+' )], [ 42, 137 ]
    , "Multi param happy case" );
is_deeply ( [$req->multi_param( foo => '\d\d' )], []
    , "Mismatch = no go" );
is ( $req->url_param( foo => '\d+' ), 1, "url_param() made its way");

done_testing;
