#!perl -w

use strict;

use Test::More qw/no_plan/;
use t::Test;
#use JSON::XS;
#my $json = JSON::XS->new->allow_blessed->pretty;
my $scratch = t::Test::Scratch->new;

sub assets {
    my $assets = File::Assets->new(base => [ "http://example.com/", $scratch->base, "/static" ], @_);
    $assets->include("css/apple.css");
    $assets->include("css/banana.css");
    $assets->include("js/apple.js");
    return ($scratch, $assets);
}
{
    my ($scratch, $assets) = assets;

    $assets->include("http://ajax.googleapis.com/ajax/libs/jquery/1.2.6/jquery.min.js", -100);
    compare($assets->export, qw(
        http://ajax.googleapis.com/ajax/libs/jquery/1.2.6/jquery.min.js
        http://example.com/static/css/apple.css
        http://example.com/static/css/banana.css
        http://example.com/static/js/apple.js
    ));
}

{
    my ($scratch, $assets) = assets(qw(output_path %n%-l.%e minify concat));

    $assets->include("http://ajax.googleapis.com/ajax/libs/jquery/1.2.6/jquery.min.js");
    compare($assets->export, qw(
        http://example.com/static/assets.css
        http://example.com/static/assets.js
        http://ajax.googleapis.com/ajax/libs/jquery/1.2.6/jquery.min.js
    ));
}

{
    my ($scratch, $assets) = assets(qw(output_path %n%-l.%e minify concat));

    $assets->include("http://ajax.googleapis.com/ajax/libs/jquery/1.2.6/jquery.min.js", -100);
    compare($assets->export, qw(
        http://ajax.googleapis.com/ajax/libs/jquery/1.2.6/jquery.min.js
        http://example.com/static/assets.css
        http://example.com/static/assets.js
    ));
}
