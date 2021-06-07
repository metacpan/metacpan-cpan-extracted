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
use Log::Any::Adapter 'JSON', $tempfile->opena;

# last line logged
sub last_line {
    my $line = ($tempfile->lines({ chomp => 1 }))[-1];
    return decode_json $line;
}

##
subtest 'first hash may not contain reserved keys' => sub {

    for my $reserved (qw/ time level category message /) {
        throws_ok(
            sub { $log->debug('foo', { $reserved => 'bar' }) },
            qr/Died: $reserved is a reserved key name/,
            "$reserved may not be used in first hashref",
        );
    }
};

##
done_testing;
