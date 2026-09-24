use v5.36;
use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

use Linux::Event::Kernel::Inotify;
use Linux::Event::Loop;

my $dir = tempdir(CLEANUP => 1);
my $path = File::Spec->catfile($dir, 'burst.txt');
open my $seed, '>', $path or die "open $path: $!";
close $seed;

my $loop = Linux::Event::Loop->new;
my $count = 0;
my $inotify = Linux::Event::Kernel::Inotify->new(loop => $loop);
my $watch = $inotify->watch(
    $path,
    on_modify => sub ($event) { $count++ },
);

my $wd = $watch->_wd;
push @{ $inotify->{pending_events} },
    map {
        [$wd, Linux::Event::Kernel::Inotify::IN_MODIFY(), 0, undef]
    } 1 .. 300;

$inotify->_drain_pending;
is($count, 256, 'one inotify drain is bounded to 256 decoded records');
is(scalar @{ $inotify->{pending_events} }, 44,
    'records beyond fairness budget remain pending');
ok($inotify->{resume_defer} && $inotify->{resume_defer}->is_active,
    'remaining records are scheduled for a later Loop turn');

ok($loop->run_once(1000) >= 1, 'deferred remainder makes Loop ready');
is($count, 300, 'later Loop turn drains the retained remainder');
is(scalar @{ $inotify->{pending_events} }, 0,
    'fairness continuation preserves every decoded record exactly once');

$inotify->close;
done_testing;
