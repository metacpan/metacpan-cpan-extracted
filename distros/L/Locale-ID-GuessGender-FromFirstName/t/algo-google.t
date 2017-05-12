#!perl -T

use strict;
use warnings;
use Test::More;

plan skip_all => 'Currently skipped, probably Google/REST interface broken';

use Locale::ID::GuessGender::FromFirstName qw(guess_gender);

# 2010-12-27: budi (algo=google) now results in 'both', not 'M'. so changed to
# use 'bambang'

#
#

SKIP: {
    skip "only for release testing", 4 unless $ENV{RELEASE_TESTING};

    is((guess_gender({algos=>['google']}, "bambang"))[0]{result}, "M", "bambang");
    is((guess_gender({algos=>['google']}, "lusi"))[0]{result}, "F", "lusi");

    my $res;

    ($res) = guess_gender({algos=>['common', 'google']}, "kasur");
    ok($res->{result} eq 'F' && $res->{algo} eq 'google', "kasur (common X -> google V)");
    ($res) = guess_gender({try_all=>1, algos=>['common', 'google']}, "bambang");
    ok($res->{result} eq 'M' && $res->{algo} eq 'common' && @{$res->{algo_res}} == 2, "bambang (common V -> google V)");
}

done_testing;
