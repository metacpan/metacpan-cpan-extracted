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
use Log::Any::Adapter 'JSON', $tempfile->opena, without_formatting => 1;

# last line logged
sub last_line {
    my $line = ($tempfile->lines({ chomp => 1 }))[-1];
    return decode_json $line;
}

##
subtest 'message with formatting codes' => sub {
    $log->debug('%s and %d');
    is last_line()->{message}, '%s and %d', 'format codes ignored';
};

##
subtest 'message with formatting codes and extra scalars' => sub {
    $log->debug('%s and %d', 'foo', 'bar');
    is last_line()->{message}, '%s and %d',                       'format codes ignored';
    is_deeply last_line()->{additional_messages}, ['foo', 'bar'], 'extra messages present';
};

##
done_testing;
