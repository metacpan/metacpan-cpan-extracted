use strict;
use Test::More;
use LWP::UserAgent::Keychain;

plan skip_all => "TEST_AUTHOR is not defined" unless $ENV{TEST_AUTHOR};
plan 'no_plan';

my $ua  = LWP::UserAgent::Keychain->new;
my $res = $ua->get("http://blog.bulknews.net/private/bookmarks.htm");
ok $res->is_success, "request is success";
like $res->content, qr/Bookmarks/;
