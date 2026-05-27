use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

my $json = $ENV{GFM_SPEC} || "$FindBin::Bin/data/gfm-spec.json";
unless (-f $json) {
    plan skip_all => "GFM spec JSON not found at $json; "
        . "regenerate via t/data/spec_to_json.pl";
}

eval { require JSON::PP; 1 } or plan skip_all => "JSON::PP not available";
require MDNormalise;
require MDSpecRunner;

plan tests => 2;
MDSpecRunner::run_spec(
    label          => 'GFM',
    json           => $json,
    known_failures => "$FindBin::Bin/data/known-failures-gfm.txt",
    render         => \&Markdown::Simple::markdown_to_html,
);
