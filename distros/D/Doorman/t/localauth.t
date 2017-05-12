#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More;

use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;

test_psgi
    app => builder {
        enable "Session";
        enable "DoormanAuthentication", authenticator => sub {
            my ($self, $env) = @_;
            my $request = Plack::Request->new($env);
            my $success = $request->param("username") eq "ohai" && $request->param("password") eq "correct";
            my $error = $success ? undef : "Wrong username or password";
            return ($success, $error);
        };

        sub {
            my ($env) = @_;
            my $body = "NOT SIGN IN";
            my $doorman = $env->{"doorman.users.authentication"};
            if ($doorman && $doorman->is_sign_in) {
                $body = "SIGN IN";
            }
            if ($env->{"doorman.users.authentication.error"}) {
                $body .= ".\n" . $env->{"doorman.users.authentication.error"};
            }

            return [200, ["Content-Type" => "text/plain"],  [$body]];
        };
    },

    client => sub {
        my ($cb) = @_;

        my @steps = (
            [GET("/xd"), "NOT SIGN IN", "Guest visits, not sign in"],
            [POST("/users/sign_in", [ username => "ohai", password => "wrong" ]), "NOT SIGN IN.\nWrong username or password", "Sign attempts with wrong password. not sign in"],
            [POST("/users/sign_in", [ username => "ohai", password => "correct" ]), "SIGN IN", "Sign attempts with correct password. sign in"],
            [GET("/xd"), "SIGN IN", "Remain sign in"],
            [GET("/users/sign_out"), "NOT SIGN IN", "Sign out attempt."],
            [GET("/xd"), "NOT SIGN IN", "Remain sign out"]
        );

        my $cookie;
        for my $step (@steps) {
            my $req = $step->[0];
            $req->header("Cookie", $cookie) if ($cookie);
            my $res = $cb->($req);
            $cookie = $res->header("Set-Cookie");
            is $res->content, $step->[1], $step->[2];
        }
    };

done_testing;
