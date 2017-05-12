use strict;
use utf8;
use warnings;
use File::Temp qw(tempdir);
use Log::Dispatch::Pipe;
use Test::Exception;
use Test::More;

plan skip_all => 'No test on Windows' if $^O =~ /^MSWin/i;

my $tmp = tempdir(CLEANUP => 1);

subtest 'Test new' => sub {

    subtest 'Fails when invalid "output_to" is given' => sub {
        local *STDERR;
        open STDERR, '>', "${tmp}/stderr"
            or die "Failed opening file: $!";

        dies_ok {
            Log::Dispatch::Pipe->new(
                min_level   => 'info',
                output_to   => 'hogefuga',
                try_at_init => 1,
                )
        }
        qr|Failed opening pipe|;
    };

    subtest 'Succeeds when invalid but try_at_init => 0' => sub {
        lives_ok {
            Log::Dispatch::Pipe->new(
                min_level   => 'info',
                output_to   => 'hogefuga',
                try_at_init => 0,
                )
        };
    };

    subtest 'Succeeds when valid' => sub {
        lives_ok {
            Log::Dispatch::Pipe->new(
                min_level   => 'info',
                output_to   => "xargs echo >> ${tmp}/test.log",
                try_at_init => 1,
                )
        };
    };
};

done_testing;
