use strict;
use warnings FATAL => 'all';

use Test::More 0.88;

use File::Spec;
use File::Temp qw( tempdir );
use Log::Dispatch;

my $dir = tempdir( CLEANUP => 1 );

# test that the same handle is returned if close-on-write is not set...

{
    my $logger = Log::Dispatch->new(
        outputs => [
            [
                'File',
                min_level => 'debug',
                newline   => 1,
                name      => 'no_caw',
                filename  => File::Spec->catfile( $dir, 'no_caw.log' ),
                close_after_write => 0,
            ],
            [
                'File',
                min_level         => 'debug',
                newline           => 1,
                name              => 'caw',
                filename          => File::Spec->catfile( $dir, 'caw.log' ),
                close_after_write => 1,
            ],
        ],
    );

    ok(
        $logger->output('no_caw')->{fh},
        'no_caw output has created a fh before first write'
    );
    ok(
        !$logger->output('caw')->{fh},
        'caw output has not created a fh before first write'
    );

    $logger->log( level => 'info', message => 'first message' );
    is(
        _slurp( $logger->output('no_caw')->{filename} ),
        "first message\n",
        'first line from no_caw output'
    );
    is(
        _slurp( $logger->output('caw')->{filename} ),
        "first message\n",
        'first line from caw output'
    );

    my %handle = (
        no_caw => $logger->output('no_caw')->{fh},
        caw    => $logger->output('caw')->{fh},
    );

    $logger->log( level => 'info', message => 'second message' );

    is(
        _slurp( $logger->output('no_caw')->{filename} ),
        "first message\nsecond message\n",
        'full content from no_caw output'
    );
    is(
        _slurp( $logger->output('caw')->{filename} ),
        "first message\nsecond message\n",
        'full content from caw output'
    );

    # check the filehandles again...
    is(
        $logger->output('no_caw')->{fh},
        $handle{no_caw},
        'handle has not changed when not using CAW'
    );
    is(
        $logger->output('caw')->{fh},
        undef,
        'handle is deleted when using CAW'
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
