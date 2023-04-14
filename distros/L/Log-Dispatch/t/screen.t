use strict;
use warnings;
use utf8;

use Test::More 0.88;

use Test::Needs {
    'IPC::Run3' => 0,
};

use FindBin   qw( $Bin );
use IPC::Run3 qw( run3 );
use Log::Dispatch::Screen;
use Log::Dispatch;
use PerlIO;

{
    my @orig_layers = PerlIO::get_layers(STDOUT);

    my $dispatch = Log::Dispatch->new;

    $dispatch->add(
        Log::Dispatch::Screen->new(
            name      => 'screen',
            min_level => 'debug',
            stderr    => 0,
            newline   => 1,
            utf8      => 1,
        )
    );

    $dispatch->log(
        level   => 'crit',
        message => '# testing'
    );

    is_deeply(
        [ PerlIO::get_layers(STDOUT) ],
        \@orig_layers,
        'STDOUT layers are not changed when Screen utf8 param is true'
    );
}

{
    my @tests = (
        [
            {
                stderr => 0,
                utf8   => 0,
            }, {
                stdout => 'test message',
                stderr => q{},
            },
        ],
        [
            {
                stderr => 1,
                utf8   => 0,
            }, {
                stdout => q{},
                stderr => 'test message',
            },
        ],
        [
            {
                stderr => 0,
                utf8   => 1,
            }, {
                stdout => "test message - \x{1f60}",
                stderr => q{},
            },
        ],
        [
            {
                stderr => 1,
                utf8   => 1,
            }, {
                stdout => q{},
                stderr => "test message - \x{1f60}",
            },
        ],
    );

    for my $test (@tests) {
        my ( $p, $expect ) = @{$test};

        subtest(
            "stderr = $p->{stderr}, utf8 = $p->{utf8}",
            sub {
                my ( $stdout, $stderr ) = _run_helper( %{$p} );

                is(
                    $stdout,
                    $expect->{stdout},
                    'got expected stdout from Screen output'
                );

                is(
                    $stderr,
                    $expect->{stderr},
                    'got expected stderr from Screen output'
                );
            }
        );
    }
}

sub _run_helper {
    my %p = @_;

    my @args;
    push @args, '--stderr' if $p{stderr};
    push @args, '--utf8'   if $p{utf8};
    my ( $stdout, $stderr );
    run3(
        [ $^X, "$Bin/screen-helper.pl", @args ],
        \undef,
        \$stdout,
        \$stderr, {
            binmode_stdout => ':encoding(UTF-8)',
            binmode_stderr => ':encoding(UTF-8)',
        },
    );

    # We want to remove all line endings on any platform.
    s/[\r\n]+$// for grep {defined} $stdout, $stderr;

    return ( $stdout, $stderr );
}

done_testing();
