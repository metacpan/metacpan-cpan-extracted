use strict;
use Test::More;

use Email::Address::JP::Mobile;
use Email::Address::JP::Mobile::NonMobile;

my @non_email = (
    'foo@',
    '@bar',
);

my @non_mobile = (
    'foo@example.com',
    'foo@dxx.pdx.ne.jp',
    'foo@mnx.ne.jp',
    'foo@bar.mnx.ne.jp',
    'foo@dct.dion.ne.jp',
    'foo@sky.tu-ka.ne.jp',
    'foo@bar.sky.tkc.ne.jp',
    'foo@em.nttpnet.ne.jp',
    'foo@bar.em.nttpnet.ne.jp',
    'foo@phone.ne.jp',
    'foo@bar.mozio.ne.jp',
    'foo@p1.foomoon.com',
    'foo@x.i-get.ne.jp',
    'foo@ez1.ido.ne.jp',
    'foo@cmail.ido.ne.jp',
);

my @docomo = (
    'foo@docomo.ne.jp',
    'rfc822.@docomo.ne.jp',
    '-everyone..-_-..annoyed-@docomo.ne.jp',
);

my @kddi = (
    'foo@ezweb.ne.jp',
    'foo@hoge.ezweb.ne.jp',
);

my @softbank = (
    'foo@jp-d.ne.jp',
    'foo@d.vodafone.ne.jp',
    'foo@softbank.ne.jp',
    'foo@disney.ne.jp',
);

my @willcom = (
    'foo@pdx.ne.jp',
    'foo@di.pdx.ne.jp',
    'foo@dj.pdx.ne.jp',
    'foo@dk.pdx.ne.jp',
    'foo@dx.pdx.ne.jp',
    'foo@wm.pdx.ne.jp',
    'foo@willcom.com',
);

my @is_mobile = (
    @docomo,
    @kddi,
    @softbank,
    @willcom,
);

for my $address (@non_email) {
    subtest "non_email: $address" => sub {
        my $carrier = Email::Address::JP::Mobile->new($address);
        is $carrier, undef, $address;
        done_testing();
    };
}

for my $address (@non_mobile) {
    subtest "non_mobile: $address" => sub {
        my $carrier = Email::Address::JP::Mobile->new($address);
        ok ! $carrier->is_mobile, $address;
        is $carrier->name, 'NonMobile', $address;
        is $carrier->carrier_letter, 'N', $address;
        
        done_testing();
    };
}

for my $address (@is_mobile) {
    subtest "is_mobile: $address" => sub {
        my $carrier = Email::Address::JP::Mobile->new($address);
        ok $carrier->is_mobile, $address;
        done_testing();
    }
}

for my $address (@docomo) {
    subtest "docomo: $address" => sub {
        my $carrier = Email::Address::JP::Mobile->new($address);
        ok $carrier->is_mobile, $address;
        
        is $carrier->name, 'DoCoMo', $address;
        is $carrier->carrier_letter, 'I', $address;
        
        done_testing();
    };
}

for my $address (@kddi) {
    subtest "kddi: $address" => sub {
        my $carrier = Email::Address::JP::Mobile->new($address);
        ok $carrier->is_mobile, $address;
        
        is $carrier->name, 'EZweb', $address;
        is $carrier->carrier_letter, 'E', $address;

        done_testing();
    };
}

for my $address (@softbank) {
    subtest "softbank: $address" => sub {
        my $carrier = Email::Address::JP::Mobile->new($address);
        ok $carrier->is_mobile, $address;
        
        is $carrier->name, 'SoftBank', $address;
        is $carrier->carrier_letter, 'V', $address;

        done_testing();
    };
}

for my $address (@willcom) {
    subtest "willcom: $address" => sub {
        my $carrier = Email::Address::JP::Mobile->new($address);
        ok $carrier->is_mobile, $address;

        is $carrier->name, 'AirH', $address;
        is $carrier->carrier_letter, 'H', $address;

        done_testing();
    }
}

done_testing();
