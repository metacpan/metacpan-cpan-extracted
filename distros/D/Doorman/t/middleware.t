#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

package Plack::Middleware::DoormanNull;
use parent "Doorman::PlackMiddleware";

package main;
use Test::More;

subtest "fq method" => sub {
    my $mw = Plack::Middleware::DoormanNull->new;
    $mw->prepare_app;
    is $mw->fq, "doorman.users.null";
    is $mw->fq("awesome"), "doorman.users.null.awesome";
};

subtest "fq method (admins scope)" => sub {
    my $mw = Plack::Middleware::DoormanNull->new(scope => "admins");
    $mw->prepare_app;
    is $mw->fq, "doorman.admins.null";
    is $mw->fq("awesome"), "doorman.admins.null.awesome";
};

subtest "env_get / env_set method" => sub {
    my $mw = Plack::Middleware::DoormanNull->new;
    $mw->prepare_app;
    $mw->{env} = {};

    $mw->{env}{"doorman.users.null.awesome"} = "stuff";
    is $mw->env_get("awesome"), "stuff";

    $mw->env_set("awesome", "value");
    is $mw->{env}{"doorman.users.null.awesome"}, "value";
    is $mw->env_get("awesome"), "value";
};

done_testing;
