use Test::Most 'die';
use Test::More::UTF8;
use Encode;
use Cpanel::JSON::XS;

my $tempfile;

BEGIN {
    use Path::Tiny;
    $tempfile = Path::Tiny->tempfile;
}

use Log::Any '$log';
use Log::Any::Adapter 'JSON', $tempfile->opena, localtime => 1;

# last line logged
sub last_line {
    my $line = ($tempfile->lines({ chomp => 1 }))[-1];
    return decode_json $line;
}

##
subtest 'message timezone offset may not be Z' => sub {
    $log->debug('where am I?');

    like last_line()->{timestamp}, qr/(?:[+-]\d\d:\d\d|Z)$/, 'timezone added';
};

##
done_testing;
