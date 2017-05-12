use strict;
use Test::More;

my @modules = qw(
    GunghoX::FollowLinks::Parser
    GunghoX::FollowLinks::Parser::HTML
    GunghoX::FollowLinks::Rule
    GunghoX::FollowLinks::Rule::Allow
    GunghoX::FollowLinks::Rule::Deny
    GunghoX::FollowLinks::Rule::URI
    GunghoX::FollowLinks
);

plan(tests => scalar @modules);
use_ok($_) for @modules;