use strict;
use warnings;

use Test::More 0.88;
use Test::Deep;
use Path::Tiny;
use Log::Dispatch;

my $tempdir = Path::Tiny->tempdir;

{
    my $logger = Log::Dispatch->new(
        outputs => [ [
            'File::Stamped',
            name => 'foo',
            min_level => 'debug',
            filename => $tempdir->child('foo.log')->stringify,
            "$]" >= 5.008 ? ( binmode => ':encoding(UTF-8)' ) : (),
            autoflush => 0,
            close_after_write => 1,
            permissions => 0777,
            syswrite => 1,
        ] ],
    );

    my $output = $logger->output('foo');

    cmp_deeply(
        $logger->output('foo'),
        noclass(superhashof({
            name => 'foo',
            min_level => '0',
            max_level => '7',
            "$]" >= 5.008 ? ( binmode => ':encoding(UTF-8)' ) : (),
            autoflush => 0,
            (Log::Dispatch->VERSION >= '2.59' ? 'close_after_write' : 'close') => 1,
            permissions => 0777,
            syswrite => 1,
            mode => '>>',
        })),
        'all Log::Dispatch::File options are preserved in the logger output',
    );
}

done_testing;

