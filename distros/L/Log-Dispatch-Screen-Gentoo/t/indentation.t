use strict;
use warnings;
use Capture::Tiny qw< :all >;
use Term::ANSIColor qw< :constants >;
use Log::Dispatch;
use Log::Dispatch::Screen::Gentoo;
use Term::GentooFunctions qw< :all >;
use Test::More 'tests' => 3;

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
    return
          ' '
        . BOLD()
        . GREEN()
        . '*'
        . RESET()
        . ( ' ' x $_[1] )
        . $_[0] . "\n";
}

is(
    capture_stdout { $log->info('Hi') },
    info_msg( 'Hi', 1 ),
    'Correct info message',
);

eindent;

is(
    capture_stdout { $log->info('Yo') },
    info_msg( 'Yo', 3 ),
    'Correct info message',
);

eindent;

is(
    capture_stdout { $log->info('Yo') },
    info_msg( 'Yo', 5 ),
    'Correct info message',
);

eoutdent;
