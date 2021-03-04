use Test::Most 'die';
use Test::More::UTF8;
use Encode;
use JSON::MaybeXS;

my $tempfile;

BEGIN {
    use Path::Tiny;
    $tempfile = Path::Tiny->tempfile;
}

use Log::Any '$log';
use Log::Any::Adapter 'JSON', $tempfile->opena;

# last line logged
sub last_line {
    my $line = ($tempfile->lines({ chomp => 1 }))[-1];
    return decode_json $line;
}

##
subtest 'message is required' => sub {

    for my $str (undef, '') {
        throws_ok(
            sub { $log->debug($str) },
            qr/Died: A log message is required/,
            'Non-empty string required',
        );
    }
};

##
done_testing;
