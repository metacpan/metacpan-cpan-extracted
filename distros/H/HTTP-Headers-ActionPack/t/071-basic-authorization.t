#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTTP::Headers::ActionPack::Authorization::Basic');
}

sub test_auth {
    my $auth = shift;

    is($auth->auth_type, 'Basic', '... got the right auth type');

    is($auth->username, 'Aladdin', '... got the expected username');
    is($auth->password, 'open sesame', '... got the expected password');

    is($auth->as_string, 'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==', '... got the right stringification')
}

test_auth(
    HTTP::Headers::ActionPack::Authorization::Basic->new_from_string(
        'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ=='
    )
);

test_auth(
    HTTP::Headers::ActionPack::Authorization::Basic->new(
        'Basic' => {
            username => 'Aladdin',
            password => 'open sesame'
        }
    )
);

test_auth(
    HTTP::Headers::ActionPack::Authorization::Basic->new(
        'Basic' => [ 'Aladdin', 'open sesame' ]
    )
);

test_auth(
    HTTP::Headers::ActionPack::Authorization::Basic->new(
        'Basic' => 'QWxhZGRpbjpvcGVuIHNlc2FtZQ=='
    )
);


done_testing;