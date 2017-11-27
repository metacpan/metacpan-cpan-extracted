#!/usr/bin/env perl

# This script demonstrates various getters of the Request object
#    of Not Even A Framework

use strict;
use warnings;

use MVC::Neaf qw(:sugar);

# Now to the NEAF itself: set common default values
neaf view => 'TT02' => 'TT' => INCLUDE_PATH => __FILE__.".data";
neaf default => '/02' =>
    { -view => 'TT02', file => 'example/02 NEAF '.MVC::Neaf->VERSION };

# Sic!
get+post '/02/request' => sub {
    my $req = shift;

    if (!$req->path_info) {
        # This actually dies but with a special-case exception
        # that Neaf converts into a proper redirect
        $req->redirect( $req->script_name . "/and/beyond" );
    };

    # Just return the data
    # Override the -view if user wants it
    return {
        title     => 'Taking apart the request object',
        header_in => $req->header_in->as_string,
        -view     => $req->param(as_json => '1') ? 'JS' : 'TT02',
        map { $_  => $req->$_ }
            qw( scheme hostname port method http_version
            path script_name path_info
            referer user_agent client_ip ),
    };
}, (
    # This may also be written as 'default => { -template => ... }'
    # generating an overridable default value for this controller only
    -template       => "main.html",
    # This is a nerdy cousin of /02/request/:param_name
    #     - smarter, but less pretty
    path_info_regex => '.*',
    # This line is just for information
    # see perl <this file> --list
    description     => 'Taking apart the request object',
);

# Do good things... and RUN!!!
neaf->run;
