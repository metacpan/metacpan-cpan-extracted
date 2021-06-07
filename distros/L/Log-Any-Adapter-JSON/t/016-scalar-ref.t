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
subtest 'log scalar ref in data struct' => sub {
    $log->info('message', { foo => \"bar" });

    is last_line()->{foo}, 'bar', 'scalar ref stringified';
};

##
done_testing;
