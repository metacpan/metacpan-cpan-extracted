use strict;
use Test::More;

subtest 'via Email::Address object' => sub {
    use Email::Address::Loose;
    use Email::Address::JP::Mobile;
    
    my ($email) = Email::Address::Loose->parse('Taro <docomo.taro.@docomo.ne.jp>');
    
    isa_ok $email, 'Email::Address',
    
    isa_ok $email->carrier, 'Email::Address::JP::Mobile::DoCoMo';
    ok $email->carrier->is_mobile,           '->carrier->is_mobile';
    is $email->carrier->name, 'DoCoMo',      '->carrier->name';
    is $email->carrier->carrier_letter, 'I', '->carrier->carrier_letter';
};

subtest 'instantiation directly' => sub {
    use Email::Address::JP::Mobile;
    
    my $carrier = Email::Address::JP::Mobile->new('Taro <docomo.taro.@docomo.ne.jp>');
    isa_ok $carrier, 'Email::Address::JP::Mobile::DoCoMo';
    ok $carrier->is_mobile,           '->carrier->is_mobile';
    is $carrier->name, 'DoCoMo',      '->carrier->name';
    is $carrier->carrier_letter, 'I', '->carrier->carrier_letter';
};

done_testing;
