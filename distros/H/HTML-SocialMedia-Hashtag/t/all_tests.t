use strict;
use warnings;

use lib qw(t/lib);

use HTML::SocialMedia::Hashtag::SearchForHashtags;
use HTML::SocialMedia::Hashtag::SearchForNicknames;

my @tests = qw(
    HTML::SocialMedia::Hashtag::SearchForHashtags
    HTML::SocialMedia::Hashtag::SearchForNicknames
);

Test::Class -> runtests( @tests );