use strict;
use warnings;
use Test::More tests => 1;

use ENV::Util;

local %ENV = (
    USER    => 'someuser',
    INVALID => 'foo@example.com',
    OK      => 'Me!',
    ALSO_OK => 'Me too',
    TOKEN   => 'some token',
);

my %redacted_env = ENV::Util::redacted_env();
is_deeply(
    \%redacted_env,
    {
        USER    => '<redacted>',
        INVALID => '<redacted>',
        OK      => 'Me!',
        ALSO_OK => 'Me too',
        TOKEN   => '<redacted>',
    }, 
    '%ENV properly redacted'
);
