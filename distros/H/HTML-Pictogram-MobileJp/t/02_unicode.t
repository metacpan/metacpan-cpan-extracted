use strict;
use warnings;
use utf8;
use HTML::Pictogram::MobileJp::Unicode;
use Test::MobileAgent qw/:all/;
use Test::More;
use HTTP::MobileAgent;

xxx('docomo', '&#xE63E;', '&#xE63E;');
xxx('ezweb', '&#xE63E;', '<img localsrc="44" />');
xxx('softbank', '&#xE63E;', '&#xE04A;');
xxx('nonmobile', '&#xE63E;', '&#xE63E;');

xxx('docomo', '&#xE70C;', '&#xE70C;'); # 拡張絵文字
xxx('softbank', '&#xE69A;', '&#xE69A;'); # unmapped

subtest 'iphone' => sub {
    my $ma = HTTP::MobileAgent->new('Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1C28 Safari/419.3');
    is(HTML::Pictogram::MobileJp::Unicode->convert($ma, '&#xE63E;'), '&#xE04A;');
};

done_testing;

sub xxx {
    my ($type, $html, $expected) = @_;
    my $ma = HTTP::MobileAgent->new(test_mobile_agent_headers($type));
    is(HTML::Pictogram::MobileJp::Unicode->convert($ma, $html), $expected, $type);
}

