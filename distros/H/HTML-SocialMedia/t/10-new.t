#!perl -wT

use strict;

use Test::Most tests => 3;

use HTML::SocialMedia;

isa_ok(HTML::SocialMedia->new(), 'HTML::SocialMedia', 'Creating HTML::SocialMedia object');
isa_ok(HTML::SocialMedia::new(), 'HTML::SocialMedia', 'Creating HTML::SocialMedia object');
isa_ok(HTML::SocialMedia->new()->new(), 'HTML::SocialMedia', 'Cloning HTML::SocialMedia object');
# ok(!defined(HTML::SocialMedia::new()));
