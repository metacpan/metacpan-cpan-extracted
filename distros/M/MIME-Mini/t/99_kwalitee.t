use Test::More;
use warnings;
use strict;
BEGIN { plan skip_all => 'release tests' unless $ENV{RELEASE_TESTING} }
use Test::Kwalitee 'kwalitee_ok';
kwalitee_ok;
done_testing;
