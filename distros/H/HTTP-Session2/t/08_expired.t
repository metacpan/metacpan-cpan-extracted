use strict;
use warnings;
use utf8;
use Test::More;
use HTTP::Session2::Expired;

my $expired = HTTP::Session2::Expired->new(
    env => {},
    secret => 33333,
);
eval { $expired->get('a') };
like $@, qr/expired/;
eval { $expired->set('a', 'b') };
like $@, qr/expired/;
eval { $expired->remove('c') };
like $@, qr/expired/;

done_testing;

