use strict;
use warnings;
use utf8;
use Test::More;
use HTTP::Session2::Base;

my $base = HTTP::Session2::Base->new(
    env => {},
    secret => 'i am secret',
);
for my $method (qw(load_session create_session finalize)) {
    eval { $base->$method() };
    like $@, qr{Abstract};
}

done_testing;

