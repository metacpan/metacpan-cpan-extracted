#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename qw(basename dirname);

# Always use latest & greatest Neaf
use lib dirname(__FILE__)."/../lib";
use MVC::Neaf;

MVC::Neaf->route( cgi => basename(__FILE__) => sub {
    my $req = shift;

    # Insert real action here

    return {foo => $req->param( foo => ".+" )};
}, method => 'GET', view => "JS", description => "RESTful web-service (get)" );

MVC::Neaf->route( cgi => basename(__FILE__) => sub {
    my $req = shift;

    # Insert real action here

    return {foo => $req->param( bar => ".+" )};
}, method => 'POST', view => "JS", description => "RESTful web-service (post)" );

MVC::Neaf->run;
