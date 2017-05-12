use strict;
use warnings;
use Test::More;

use Email::Address::JP::Mobile;

subtest "change utf-8" => sub {
    
    local $Email::Address::JP::Mobile::NonMobile::Encoding = 'utf-8';
    
    my $carrier = Email::Address::JP::Mobile::NonMobile->new;
    
    ok $carrier->mime_encoding, 'mime_encoding';
    is $carrier->mime_encoding->name, 'MIME-Header';
    
    ok $carrier->send_encoding, 'send_encoding';
    is $carrier->send_encoding->name, 'utf-8-strict';
    
    ok $carrier->parse_encoding, 'parse_encoding';
    is $carrier->parse_encoding->name, 'utf-8-strict';
};

subtest "change UTF-8" => sub {
    
    local $Email::Address::JP::Mobile::NonMobile::Encoding = 'UTF-8';
    
    my $carrier = Email::Address::JP::Mobile::NonMobile->new;
    
    ok $carrier->mime_encoding, 'mime_encoding';
    is $carrier->mime_encoding->name, 'MIME-Header';
    
    ok $carrier->send_encoding, 'send_encoding';
    is $carrier->send_encoding->name, 'utf-8-strict';
    
    ok $carrier->parse_encoding, 'parse_encoding';
    is $carrier->parse_encoding->name, 'utf-8-strict';
};

done_testing;
