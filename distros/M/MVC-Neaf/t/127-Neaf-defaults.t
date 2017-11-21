#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use JSON;

use MVC::Neaf;

MVC::Neaf->route( '/foo/bar' => sub { +{} }
    , default => { lang => 'Perl' }
    , -view => 'JS'
    , -type => 'x-text/jason'
);

MVC::Neaf->set_path_defaults( '/foo' => { answer => 42 } );
MVC::Neaf->set_path_defaults( '/foo' => { fine => 137 } );
MVC::Neaf->set_path_defaults( '/f' => { rubbish => 314 } );

my ($status, $head, $result)
    = MVC::Neaf->run_test( { REQUEST_URI => '/foo/bar' } );

is $status, 200, "Request ok";
is_deeply( decode_json($result)
    , { lang => 'Perl', answer => 42, fine => 137 }
    , "Returned value as exp" );

is (scalar $head->header('content_type')
    , 'x-text/jason; charset=utf-8'
    , 'Custom -type propagates');

done_testing;
