use strict;
use Test::More;

my @modules = qw(
    GunghoX::FollowLinks::Parser::HTML
    GunghoX::FollowLinks::Rule::HTML::SelectedTags
);

plan(tests => scalar @modules);
use_ok($_) for @modules;

