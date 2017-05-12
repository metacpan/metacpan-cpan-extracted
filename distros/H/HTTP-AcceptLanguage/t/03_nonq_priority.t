use strict;
use warnings;
use utf8;
use Test::More;
use HTTP::AcceptLanguage;

# Priority detection for language tags that does not have q= parameters.

subtest 'new spec' => sub {
    my $accept_language = HTTP::AcceptLanguage->new('en, da');
    is $accept_language->match(qw/ da en /), 'en';
    is $accept_language->match(qw/ en da /), 'en';
};

subtest 'old spec' => sub {
    local $HTTP::AcceptLanguage::MATCH_PRIORITY_0_01_STYLE = 1;

    my $accept_language = HTTP::AcceptLanguage->new('en, da');
    is $accept_language->match(qw/ da en /), 'da';
    is $accept_language->match(qw/ en da /), 'en';
};

done_testing;

