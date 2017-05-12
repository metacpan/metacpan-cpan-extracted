#!/usr/bin/env perl

# plackup openid-with-local.psgi & ; open http://localhost:5000

use strict;
use File::Spec;
my $DIR;

BEGIN {
    (undef, $DIR, undef) = File::Spec->splitpath( File::Spec->rel2abs(__FILE__) );
    unshift @INC, "$DIR/../lib";
}

use Plack::Builder;
use Plack::Request;
use Plack::Util;
use Data::Dumper;

my $app = sub {
    my $env = shift;
    my $doorman_o = $env->{'doorman.users.openid'};
    my $doorman_a = $env->{'doorman.users.authentication'};

    my $doorman = Plack::Util::inline_object(
        is_sign_in => sub {
            $doorman_o->is_sign_in || $doorman_a->is_sign_in
        },
        username => sub {
            my $username = "";
            $username .= $doorman_a->is_sign_in if $doorman_a->is_sign_in;
            $username .= "(" . $doorman_o->verified_identity_url . ")" if $doorman_o->is_sign_in;
            return $username;
        },
        sign_in_path  => sub { $doorman_a->sign_in_path },
        sign_out_path => sub { $doorman_a->sign_out_path },
        errors => sub {
            return grep { $_ } ($env->{"doorman.users.authentication.error"}, $env->{"doorman.users.openid.error"});
        }
    );

    my $status = $doorman->is_sign_in ? "Logged In As @{[ $doorman->username ]}" : "Not Logged In";

    return [200, ['Content-Type' => 'text/html'], [
        qq{<html><body><nav>},
        qq{<a href="/">Home</a> },
        qq{<a href="/page1">Page 1</a> },
        qq{<a href="/page2">Page 2</a> },
        qq{<a href="/page3">Page 3</a> },
        $doorman->is_sign_in ? qq{ <a href="@{[ $doorman->sign_out_path ]}">Logout</a>} : qq{},
        qq{</nav>},
        qq{<p>$status</p>},
        map { "<p style=\"color:red;\">$_</p>" } ($doorman->errors),
        qq{<form method="post" action="@{[ $doorman->sign_in_path ]}">OpenID:<input type="text" name="openid" autofocus><hr>Username: <input type="text" name="username"><br>Password<input type="password" name="password"><input type="submit" value="Sign In"></form></html>},
        '<hr><pre>' . Data::Dumper->Dump([$env], ['env']) . "</pre>",
        "</body></html>"
    ]];
};

builder {
    enable "Session::Cookie";
    enable "DoormanAuthentication", authenticator => sub {
        my ($self, $env) = @_;
        my $req = Plack::Request->new($env);
        my ($u, $p) = ($req->param("username"), $req->param("password"));
        if ($u || $p) {
            if ($u eq "john" && $req->param("password") eq "correct") {
                return "john";
            }
            else {
                return (undef, "The username is not john, or the password is not correct.");
            }
        }
        return undef;
    };
    enable "DoormanOpenID";
    $app;
};
