use strict;
use warnings;
use HTTP::MobileAgent;
use HTTP::MobileAgent::Plugin::Charset;
use Test::More 0.98;


my @parts = (
    [
        'PC',
'Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1.8) Gecko/20071019 Firefox/2.0.0.8',
        {
            can_display_utf8 => 'utf8',
            encoding         => 'utf-8',
        },
    ],
    [
        'docomo foma',
        'DoCoMo/2.0 N905iBiz(c100;TJ)',
        { can_display_utf8 => 'utf8', encoding => 'x-utf8-docomo', },
    ],
    [
        'docomo mova',
        'DoCoMo/1.0/D501i',
        {
            can_display_utf8 => 'no utf8',
            encoding         => 'x-sjis-docomo',
        },
    ],
    [
        'vodafone utf8',
'Vodafone/1.0/V802SE/SEJ001/SNXXXXXXXXX Browser/SEMC-Browser/4.1 Profile/MIDP-2.0 Configuration/CLDC-1.10',
        {
            can_display_utf8 => 'utf8',
            encoding         => 'x-utf8-vodafone',
        }
    ],
    [
        'vodafone sjis',
        'J-PHONE/2.0/J-DN02',
        {
            can_display_utf8 => 'no utf8',
            encoding         => 'x-sjis-vodafone',
        }
    ],
    [
        'willcom',
        'Mozilla/3.0(DDIPOCKET;JRC/AH-J3001V,AH-J3002V/1.0/0100/c50)CNF/2.0',
        {
            can_display_utf8 => 'no utf8',
            encoding         => 'x-sjis-airh',
        },
    ],
    [
        'ez sjis',
        'UP.Browser/3.01-HI01 UP.Link/3.4.5.2',
        {
            can_display_utf8 => 'no utf8',
            encoding         => 'x-sjis-ezweb-auto',
        }
    ],
    [
        'ez utf8',
        'KDDI-TS21 UP.Browser/6.0.2.276 (GUI) MMP/1.1',
        {
            can_display_utf8 => 'no utf8',
            encoding         => 'x-sjis-ezweb-auto',
        }
    ]
);
for my $part (@parts) {
    subtest $part->[0] => sub {
        local $ENV{HTTP_USER_AGENT} = $part->[1];

        my $agent = HTTP::MobileAgent->new;
        is_deeply(+{
            can_display_utf8 => $agent->can_display_utf8 ? 'utf8' : 'no utf8',
            encoding         => $agent->encoding,
        }, $part->[2]);
    };
}
done_testing;

