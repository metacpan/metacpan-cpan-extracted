use strict;
use warnings;
use Test::More;
use HTTP::Session2::Random;

if ($HTTP::Session2::Random::URANDOM_FH) {
    diag "/dev/urandom available";
    my $token_urandom1 = HTTP::Session2::Random::generate_session_id();
    my $token_urandom2 = HTTP::Session2::Random::generate_session_id();
    my $token_perl = sub {
        local $HTTP::Session2::Random::URANDOM_FH; # Use original mode.
        HTTP::Session2::Random::generate_session_id();
    }->();
    diag "/dev/urandom(1): " . $token_urandom1;
    diag "/dev/urandom(2): " . $token_urandom2;
    diag "perl:            " . $token_perl;
    is length($token_urandom1), length($token_perl);

    isnt $token_urandom1, $token_urandom2;
} else {
    diag "No /dev/urandom";
}

subtest 'perl random test', sub {
    local $HTTP::Session2::Random::URANDOM_FH; # Use original mode.
    my $token = HTTP::Session2::Random::generate_session_id();
    is length($token), 31;
};

done_testing;
