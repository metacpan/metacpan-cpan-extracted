use Test::More tests => 2;
BEGIN { use_ok('Log::Lite') };

use POSIX qw(strftime);
use Log::Lite qw(logrotate logmode logpath log);

my $logpath;
$logpath = 'log';
$logpath = '/tmp' if -d '/tmp';
logpath($logpath);
log('test', '123456789', 'abcdefg');
my $date_str = strftime "%Y%m%d", localtime;
my $file = "$logpath/test_$date_str".".log";
open my $fh,"<",$file;
my $content = <$fh>;
close $fh;
unlink $file;

like($content, qr/\d{4}\-\d{2}\-\d{2}\s+\d{2}\:\d{2}\:\d{2}\s+123456789\s+abcdefg/, 'content');
