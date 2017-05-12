#!perl -wT

use strict;

use Test::Most tests => 2;

use HTML::SocialMedia;

isa_ok(HTML::SocialMedia->new(), 'HTML::SocialMedia', 'Creating HTML::SocialMedia object');
ok(!defined(HTML::SocialMedia::new()));
