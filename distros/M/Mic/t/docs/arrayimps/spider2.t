use strict;
use Scalar::Util qw( reftype );
use Test::Lib;
use Test::More tests => 1;

SKIP: {
    skip "Perl version $] lower than 5.16", 1 if $] lt '5.016';
    require Example::ArrayImps::Spider_v2;

    my $spider = Example::ArrayImps::Spider_v2::->new;

    $spider->url = 'http://example.com';
    my $msg = $spider->crawl;
    is $msg, 'Crawling over http://example.com';
}
