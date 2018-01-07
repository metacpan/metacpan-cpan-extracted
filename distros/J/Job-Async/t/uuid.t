use strict;
use warnings;

use Test::More;

use Job::Async::Utils;

my %uniq;
for my $uuid (map { Job::Async::Utils::uuid() } 1..100) {
    is(++$uniq{$uuid}, 1, 'UUID is unique');
    like($uuid, qr{^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$}, 'UUID format matches') or note explain $uuid;
}

done_testing;


