use strict;
use utf8;
use warnings;
use File::Temp qw(tempdir);
use Log::Dispatch::Pipe;
use Test::Exception;
use Test::More;

plan skip_all => 'No test on Windows' if $^O =~ /^MSWin/i;

my $tmp = tempdir(CLEANUP => 1);

sub touch {
    my $file = shift;
    my $now = time;
    utime($now, $now, $file)
    || open(my $fh, '>>', $file)
    || die "touch failed on file: $file";
}

subtest 'Test log_message output' => sub {
    my $perl        = $^X;
    my $output_file = "${tmp}/test.log";
    touch $output_file;

    subtest 'Output log' => sub {
        my $log = Log::Dispatch::Pipe->new(
            min_level => 'info',
            output_to => "${perl} t/bin/write.pl ${output_file}",
            binmode   => ':utf8',
            newline   => 1,
        );

        ok $log->log(level => 'info', message => 'あいうえお');
        ok $log->log(level => 'info', message => 'かきくけこ');
    };

    subtest 'Check written log' => sub {
        my $content = do {
            open my $fh, '<', $output_file
                or die "Failed opening output file: $!";
            binmode $fh, ':utf8';
            local $/ = undef;
            <$fh>;
        };

        is $content, <<END;
あいうえお
かきくけこ
END
    };
};

subtest 'Test log_message fails' => sub {

    subtest 'Fails if output_to is invald' => sub {
        local *STDERR;
        open STDERR, '>', "${tmp}/stderr"
            or die "Failed opening file: $!";

        my $log = Log::Dispatch::Pipe->new(
            min_level   => 'info',
            output_to   => 'hogehoge',
            try_at_init => 0,
        );

        dies_ok {
            $log->log(level => 'info', message => 'Should fail')
        }
        qr|Failed opening pipe|;
    };
};

done_testing;
