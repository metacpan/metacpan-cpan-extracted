#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More;
use Doorman::Scope;

{
    my $x = Doorman::Scope->new;
    is $x->scope_path,    "/users";
    is $x->sign_in_path,  "/users/sign_in";
    is $x->sign_out_path, "/users/sign_out";

    my $users = Doorman::Scope->new(name => "users");
    is $users->scope_path,    "/users";
    is $users->sign_in_path,  "/users/sign_in";
    is $users->sign_out_path, "/users/sign_out";

    my $admins = Doorman::Scope->new(name => "admins");
    is $admins->scope_path,    "/admins";
    is $admins->sign_in_path,  "/admins/sign_in";
    is $admins->sign_out_path, "/admins/sign_out";
}

{
    my $x = Doorman::Scope->new;
    is $x->scope_url,    "http://localhost/users";
    is $x->sign_in_url,  "http://localhost/users/sign_in";
    is $x->sign_out_url, "http://localhost/users/sign_out";
}

{
    my $admins = Doorman::Scope->new(name => "admins");
    is $admins->scope_url,    "http://localhost/admins";
    is $admins->sign_in_url,  "http://localhost/admins/sign_in";
    is $admins->sign_out_url, "http://localhost/admins/sign_out";
}

{
    my $admins = Doorman::Scope->new(root_url => "http://abcd.com/app");
    is $admins->scope_url,    "http://abcd.com/app/users";
    is $admins->sign_in_url,  "http://abcd.com/app/users/sign_in";
    is $admins->sign_out_url, "http://abcd.com/app/users/sign_out";
}

{
    my $admins = Doorman::Scope->new(name => "admins", root_url => "http://abcd.com/app");
    is $admins->scope_url,    "http://abcd.com/app/admins";
    is $admins->sign_in_url,  "http://abcd.com/app/admins/sign_in";
    is $admins->sign_out_url, "http://abcd.com/app/admins/sign_out";
}

done_testing;
