use strict;
use warnings;
use Capture::Tiny qw< :all >;
use Term::ANSIColor qw< :constants >;
use Log::Dispatch;
use Log::Dispatch::Screen::Gentoo;
use Test::More 'tests' => 8;

my $log = Log::Dispatch->new(
    'outputs' => [
        [
            'Screen::Gentoo',
            'min_level' => 'debug',
            'stderr'    => 1,
            'newline'   => 1,
        ],
    ],
);

sub info_msg {
    return ' ' . BOLD() . GREEN() . '*' . RESET() . ' ' . $_[0] . "\n";
}

sub warn_msg {
    return ' ' . BOLD() . YELLOW() . '*' . RESET() . ' ' . $_[0] . "\n";
}

sub error_msg {
    return ' ' . BOLD() . RED() . '*' . RESET() . ' ' . $_[0] . "\n";
}

foreach my $method ( qw< debug info notice > ) {
    my $msg = "$method msg";
    is(
        capture_stdout { $log->$method($msg) },
        info_msg($msg),
        "$method message",
    );
}

foreach my $method ( qw< warning > ) {
    my $msg = "$method msg";
    is(
        capture_stdout { $log->$method($msg) },
        warn_msg($msg),
        "$method message",
    );
}

foreach my $method ( qw< error critical alert emergency > ) {
    my $msg = "$method msg";
    is(
        capture_stdout { $log->$method($msg) },
        error_msg($msg),
        "$method message",
    );
}
