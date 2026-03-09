use v5.36;
use Test2::V0;
use Time::HiRes qw(sleep);

use Linux::Event::Proactor;

my $loop = Linux::Event::Proactor->new;
my @seen;

$loop->after(
    0.03,
    on_complete => sub ($op, $result, $data) {
        push @seen, 'late';
    },
);

$loop->after(
    0.01,
    on_complete => sub ($op, $result, $data) {
        push @seen, 'early';
    },
);

sleep 0.015;
$loop->run_once;

is(\@seen, ['early'], 'only early timer fired first');

sleep 0.025;
$loop->run_once;

is(\@seen, ['early', 'late'], 'late timer fired later');

done_testing;
