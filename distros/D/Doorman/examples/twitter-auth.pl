#!/usr/bin/env perl

use strict;
use File::Spec;
my $DIR;

BEGIN {
    (undef, $DIR, undef) = File::Spec->splitpath( File::Spec->rel2abs(__FILE__) );
    unshift @INC, "$DIR/../lib";
}

use YAML;
use Data::Dumper;

my $app = sub {
    my $env = shift;

    # Retrive the Plack::Middleware::DoormanTwitter object
    my $doorman = $env->{'doorman.users.twitter'};

    my $status = $doorman->is_sign_in ? "Logged In As @{[ $doorman->twitter_screen_name ]}" : "Not Logged In";

    return [200, ['Content-Type' => 'text/html'], [
        qq{<html><body><nav>},
        qq{<a href="/">Home</a> },
        qq{<a href="/page1">Page 1</a> },
        qq{<a href="/page2">Page 2</a> },
        qq{<a href="/page3">Page 3</a> },
        $doorman->is_sign_in ? qq{ <a href="@{[ $doorman->sign_out_path ]}">Logout</a>} : qq{ <a href="@{[ $doorman->sign_in_path ]}">Login</a>},
        qq{</nav>},
        qq{<p>$status</p>},
        '<hr><pre>' . Data::Dumper->Dump([$env->{'psgix.session'}], ['session']) . "</pre>",
        '<hr><pre>' . Data::Dumper->Dump([$env], ['env']) . "</pre>",
        "</body></html>"
    ]];
};


# Register your test app at http://twitter.com/oauth_clients
# Must make it a 'broweser app' with 'callback' value in order to get it working.
# However, The 'callback' value in the app setting can be a random valid URL,
# the real, useful, proper callback url is given in the middleware.


unless (-f "$DIR/twitter.yml") {
    die "Construct $DIR/twitter.yml first, see $DIR/twitter.yml.example for example.\n";
}

my $twitter_config = YAML::LoadFile("$DIR/twitter.yml");

use Plack::Builder;
builder {
    enable "Session::Cookie";
    enable "DoormanTwitter", root_url => 'http://localhost:5000', scope => 'users',
        consumer_key    => $twitter_config->{consumer_key},
        consumer_secret => $twitter_config->{consumer_secret};
    $app;
};
