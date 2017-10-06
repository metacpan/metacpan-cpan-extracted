use strict;
use warnings FATAL => 'all';

use Test::More 0.88;

use File::Spec;
use File::Temp qw( tempdir );
use Log::Dispatch;

my $dir = tempdir( CLEANUP => 1 );

{
    my $logger = Log::Dispatch->new(
        outputs => [
            [
                'File',
                min_level => 'debug',
                newline   => 1,
                name      => 'lazy_open',
                filename  => File::Spec->catfile( $dir, 'lazy_open.log' ),
                lazy_open => 1,
            ],
        ],
    );

    ok(
        !$logger->output('lazy_open')->{fh},
        'lazy_open output has not created a fh before first write'
    );

    $logger->log( level => 'info', message => 'first message' );
    is(
        _slurp( $logger->output('lazy_open')->{filename} ),
        "first message\n",
        'first line from lazy_open output'
    );

    ok(
        $logger->output('lazy_open')->{fh},
        'lazy_open output has still an open fh'
    );

    $logger->log( level => 'info', message => 'second message' );

    is(
        _slurp( $logger->output('lazy_open')->{filename} ),
        "first message\nsecond message\n",
        'full content from caw output'
    );

    ok(
        $logger->output('lazy_open')->{fh},
        'lazy_open output has still an open fh'
    );
}

done_testing();

sub _slurp {
    open my $fh, '<', $_[0]
        or die "Cannot read $_[0]: $!";
    my $s = do {
        local $/ = undef;
        <$fh>;
    };
    close $fh or die $!;
    return $s;
}
