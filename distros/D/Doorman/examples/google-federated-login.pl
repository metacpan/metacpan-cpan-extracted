#!/usr/bin/env perl

# plackup openid-auth.pl &; open http://localhost:5000

use strict;
use File::Spec;
my $DIR;

BEGIN {
    (undef, $DIR, undef) = File::Spec->splitpath( File::Spec->rel2abs(__FILE__) );
    unshift @INC, "$DIR/../lib";
}

use Data::Dumper;

my $app = sub {
    my $env = shift;
    my $doorman = $env->{'doorman.users.googlefederatedlogin'};

    my $status = $doorman->is_sign_in ? "Logged In As @{[ $doorman->verified_identity_url ]}" : "Not Logged In";

    return [200, ['Content-Type' => 'text/html'], [
        qq{<html><body><nav>},
        qq{<a href="/">Home</a> },
        qq{<a href="/page1">Page 1</a> },
        qq{<a href="/page2">Page 2</a> },
        qq{<a href="/page3">Page 3</a> },
        $doorman->is_sign_in ? qq{ <a href="@{[ $doorman->sign_out_path ]}">Logout</a>} : qq{},
        qq{</nav>},
        qq{<p>$status</p>},
        qq{<form method="post" action="@{[ $doorman->sign_in_path ]}">Google Account (gmail address):<input type="text" name="google-federated-login" autofocus><input type="submit" value="Sign In"></form></html>},
        '<hr><pre>' . Data::Dumper->Dump([$env], ['env']) . "</pre>",
        "</body></html>"
    ]];
};

use Plack::Builder;
builder {
    enable "Session::Cookie";
    enable "DoormanGoogleFederatedLogin", scope => 'users';
    $app;
};
