#!perl -w

use strict;

use Test::More qw/no_plan/;
use t::Test;
my $assets = t::Test->assets;
my $scratch = t::Test->scratch;

File::Assets::Util->types->addType(MIME::Type->new(type => "application/x-javascript", extensions => [qw/js/]));

ok($assets->include("css/apple.css"));
ok($assets->include("js/apple.js")); # Not a great test, as MIME::T

compare($assets->export, qw(
    http://example.com/static/css/apple.css
    http://example.com/static/js/apple.js
));
