use strict;
use warnings;
use Digest::GOST;
use Digest::GOST::CryptoPro;
use Test::More;

eval "use Test::LeakTrace; 1" or do {
    plan skip_all => 'Test::LeakTrace is not installed.';
};

for my $m (qw(Digest::GOST Digest::GOST::CryptoPro)) {
    my $try = sub {
        my $gost = $m->new;
        $gost->add('foobar');
    };

    $try->();

    is(leaked_count($try), 0, 'leaks');
}

done_testing;
