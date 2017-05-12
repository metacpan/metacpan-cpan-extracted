use strict;
use utf8;
use warnings;
use File::Temp qw(tempdir);
use Log::Dispatch::Pipe;
use Test::More;
use Time::Piece;

my $tmp = tempdir(CLEANUP => 1);

subtest 'Test output to cronolog' => sub {

    my $date = Time::Piece->localtime->strftime('%Y-%m-%d');

    subtest 'Write log' => sub {
        my $log = Log::Dispatch::Pipe->new(
            min_level => 'info',
            output_to => "cronolog ${tmp}/%Y-%m-%d/test.log",
            binmode   => ':utf8',
            newline   => 1,
        );

        ok $log->log(level => 'info', message => 'あいうえお');
        ok $log->log(level => 'info', message => 'あいうえお');
    };

    subtest 'Check log' => sub {
        my $file    = "${tmp}/${date}/test.log";
        my $content = do {
            open my $fh, '<', $file or die "Failed opening file: $!";
            local $/ = undef;
            binmode $fh, ':utf8';
            <$fh>;
        };

        is $content, <<END;
あいうえお
あいうえお
END
    };
};

done_testing;
