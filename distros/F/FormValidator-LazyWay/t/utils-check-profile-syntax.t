use strict;
use warnings;
use Test::More qw/no_plan/;
use Test::Exception;
use FormValidator::LazyWay::Utils;
use utf8;

ok( FormValidator::LazyWay::Utils::check_profile_syntax(
        {   
            optional    => [],
            required    => [],
            defaults    => [],
            want_array  => [],
            lang        => [],
            use_loose   => [],
            use_foo     => [],
        }
    )
);

throws_ok {
    FormValidator::LazyWay::Utils::check_profile_syntax(
        {   optional => [],
            oppai    => [],
        }
    );
}
qr/oppai/, 'errr!';

