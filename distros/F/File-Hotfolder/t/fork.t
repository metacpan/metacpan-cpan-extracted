use strict;
use warnings;
use v5.10;

use Test::More;
use Time::HiRes;
use Capture::Tiny ':all';
use File::Temp qw(tempdir);
use File::Hotfolder;

eval 'require AnyEvent';
if ($@) {
    plan skip_all => 'test requires AnyEvent';
    exit;
}

unless ($ENV{RELEASE_TESTING}) {
    plan skip_all => 'skipped unless RELEASE_TESTING is set';
    exit;
}

sub touch($) {
    my $f; open($f, '>', shift) ? close($f) : die "open: $!";
}

my $dir = tempdir( CLEANUP => 1 );

my ($stdout) = capture_stdout {
    my $hf = File::Hotfolder->new(
        watch    => $dir,
        print    => FOUND_FILE | KEEP_FILE,
        callback => sub {
            sleep $1 if $_[0] =~ /([0-9.]+)$/;
        },
        fork     => 0,
    );

    my $quit = AnyEvent->condvar;
    my $timer = AnyEvent->timer (after => 2, cb => sub { $quit->send });

    my $watch = $hf->anyevent;

    touch "$dir/1.5";
    touch "$dir/0.5";
    say "meanwhile...";

    $quit->recv;
};

is $stdout, <<OUT;
meanwhile...
found $dir/1.5
found $dir/0.5
keep $dir/0.5
keep $dir/1.5
OUT

done_testing;
