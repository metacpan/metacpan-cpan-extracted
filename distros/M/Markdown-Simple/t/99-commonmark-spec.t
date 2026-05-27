use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

my $spec = $ENV{COMMONMARK_SPEC} || "$FindBin::Bin/data/commonmark-spec.json";
unless (-f $spec) {
    plan skip_all => "CommonMark spec JSON not found at $spec; "
        . "download from https://spec.commonmark.org/0.31.2/spec.json "
        . "and place at t/data/commonmark-spec.json";
}

eval { require JSON::PP; 1 } or plan skip_all => "JSON::PP not available";
require MDNormalise;
require MDSpecRunner;

plan tests => 2;
require Markdown::Simple;
MDSpecRunner::run_spec(
    label          => 'CommonMark',
    json           => $spec,
    known_failures => "$FindBin::Bin/data/known-failures-commonmark.txt",
    render         => sub { Markdown::Simple::markdown_to_html($_[0], { gfm => 0 }) },
);
