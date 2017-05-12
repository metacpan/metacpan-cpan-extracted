use strict;
use Test::More tests => 5;

use Email::Address::JP::Mobile;

subtest "non mobile" => sub {
    my $carrier = Email::Address::JP::Mobile::NonMobile->new;
    
    ok $carrier->mime_encoding, 'mime_encoding';
    is $carrier->mime_encoding->name, 'MIME-Header-ISO_2022_JP';
    
    ok $carrier->send_encoding, 'send_encoding';
    is $carrier->send_encoding->name, 'iso-2022-jp';
    
    ok $carrier->parse_encoding, 'parse_encoding';
    is $carrier->parse_encoding->name, 'iso-2022-jp';
};

subtest "docomo" => sub {
    my $carrier = Email::Address::JP::Mobile::DoCoMo->new;
    
    ok $carrier->mime_encoding, 'mime_encoding';
    is $carrier->mime_encoding->name, 'MIME-Header-JP-Mobile-DoCoMo-SJIS';
    
    ok $carrier->send_encoding, 'send_encoding';
    is $carrier->send_encoding->name, 'x-sjis-docomo';
    
    ok $carrier->parse_encoding, 'parse_encoding';
    is $carrier->parse_encoding->name, 'iso-2022-jp';
};

subtest "kddi" => sub {
    my $carrier = Email::Address::JP::Mobile::EZweb->new;
    
    ok $carrier->mime_encoding, 'mime_encoding';
    is $carrier->mime_encoding->name, 'MIME-Header-JP-Mobile-KDDI-SJIS';
    
    ok $carrier->send_encoding, 'send_encoding';
    is $carrier->send_encoding->name, 'x-sjis-kddi-auto';
    
    ok $carrier->parse_encoding, 'parse_encoding';
    is $carrier->parse_encoding->name, 'x-iso-2022-jp-kddi-auto';
};


subtest "softbank" => sub {
    my $carrier = Email::Address::JP::Mobile::SoftBank->new;
    
    ok $carrier->mime_encoding, 'mime_encoding';
    is $carrier->mime_encoding->name, 'MIME-Header-JP-Mobile-SoftBank-UTF8';
    
    ok $carrier->send_encoding, 'send_encoding';
    is $carrier->send_encoding->name, 'x-utf8-softbank';
    
    ok $carrier->parse_encoding, 'parse_encoding';
    is $carrier->parse_encoding->name, 'iso-2022-jp';
};

subtest "willcom" => sub {
    my $carrier = Email::Address::JP::Mobile::AirH->new;
    
    ok $carrier->mime_encoding, 'mime_encoding';
    is $carrier->mime_encoding->name, 'MIME-Header-JP-Mobile-AirH-SJIS';
    
    ok $carrier->send_encoding, 'send_encoding';
    is $carrier->send_encoding->name, 'x-sjis-airh';
    
    ok $carrier->parse_encoding, 'parse_encoding';
    is $carrier->parse_encoding->name, 'x-iso-2022-jp-airh';
};
