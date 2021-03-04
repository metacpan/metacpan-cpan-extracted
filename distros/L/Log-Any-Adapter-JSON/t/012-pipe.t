use Test::Most 'die';

use Test::More::UTF8;
use Encode;
use JSON::MaybeXS;

my $tempfile;
my $cat_pipe;

BEGIN {
    plan skip_all => 'This test requires cat' if $^O eq 'MSWin32';
    use Path::Tiny;
    $tempfile = Path::Tiny->tempfile;
    open($cat_pipe, '|-', "cat -n >> $tempfile") or die "Died: Could not open pipe: $@";
}

use Log::Any '$log';
use Log::Any::Adapter 'JSON', $cat_pipe;


# last line logged
sub last_line {
    my $line = ($tempfile->lines({ chomp => 1 }))[-1];
    return $line;
}

subtest 'Logging to pipe' => sub {
    $log->debug('hello, world');
    close $cat_pipe;
    like( last_line(), qr/\s*1\s+\{/, 'log entry OK');
};

done_testing;

