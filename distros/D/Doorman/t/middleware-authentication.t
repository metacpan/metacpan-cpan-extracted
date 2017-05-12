#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More;

use Doorman::Scope;
use Plack::Middleware::DoormanAuthentication;

{
    my $mw = Plack::Middleware::DoormanAuthentication->new;
    $mw->prepare_app;
    $mw->scope_object( Doorman::Scope->new );

    is $mw->scope_path, "/users";
    is $mw->sign_in_path, "/users/sign_in";
    is $mw->sign_out_path, "/users/sign_out";
}

{
    my $mw = Plack::Middleware::DoormanAuthentication->new( root_url => "http://example.com/app");
    $mw->prepare_app;
    $mw->scope_object( Doorman::Scope->new(root_url => "http://example.com/app") );

    is $mw->scope_url,    "http://example.com/app/users";
    is $mw->sign_in_url,  "http://example.com/app/users/sign_in";
    is $mw->sign_out_url, "http://example.com/app/users/sign_out";
}

done_testing;
