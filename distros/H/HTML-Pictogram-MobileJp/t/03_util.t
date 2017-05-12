use strict;
use warnings;
use Test::More;
use HTML::Pictogram::MobileJp::Util qw/is_iphone/;

subtest 'is_iphone' => sub {
    ok is_iphone('Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1C28 Safari/419.3');
    ok !is_iphone('Mozilla/5.0 (PDA; NF34PPC/1.0; like Gecko) NetFront/3.4');
};

done_testing;

