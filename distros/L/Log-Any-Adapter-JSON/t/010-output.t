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
subtest 'plain string' => sub {
    $log->debug('hello, world');

    cmp_deeply(
        last_line(),
        {
            message  => 'hello, world',
            category => 'main',
            level    => 'debug',
            time     => re('^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{0,6}Z$'),
        },
        'plain string logged as-is',
    );

    $log->debug('こんにちは世界');

    cmp_deeply(
        last_line(),
        {
            message => 'こんにちは世界',
            category => 'main',
            level    => 'debug',
            time     => re('^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{0,6}Z$'),
        },
        'plain high-bit utf8 string logged as-is',
    );
};

##
subtest 'formatted message' => sub {
    my $string = '%s %s and %s';
    my @values = ('green', 'eggs', 'ham', 'I do not like them', 'Sam-I-Am');

    my $error = qr/3 scalar values are required/;
    throws_ok { $log->debug($string) } $error,                        'croaks with pattern and no values';
    throws_ok { $log->debug($string, @values[0,1]) } $error,          'croaks with pattern and not enough values';

    $log->debug($string, @values[0..2]);
    is last_line()->{message}, 'green eggs and ham',                  'formatted message logged correctly';

    $log->debug($string, @values);
    is last_line()->{message}, 'green eggs and ham',                  'formatted message logged correctly with additional scalars';
    cmp_deeply last_line()->{additional_messages}, bag(@values[3,4]), 'additional strings are in the additional_messages field';

    $log->debug($string, @values[0,1], 'こんにちは世界', '🇯🇵');
    is last_line()->{message}, 'green eggs and こんにちは世界',         'formatted high-bit utf-8 message logged correctly';
    is_deeply last_line()->{additional_messages}, ['🇯🇵'],             'additional string is in the additional_messages field';

    $log->debug('%s %d', 'Route', '66');
    is last_line()->{message}, 'Route 66',                            '`%d` token used correctly';

    throws_ok { $log->debug('%s %d', 'Route', 'sixty-six') }
              qr/Argument "sixty-six" isn't numeric in sprintf/,      '`%d` token throws when used incorrectly';

};

## The Mike Earley Memorial Kitchen Sink Test
##
subtest 'structured data' => sub {
    my $pattern = 'Green Eggs and %s';
    my @values  = ('Ham', 'I do not like them, Sam-I-Am');
    my %data    = ( author => 'Dr. Seuss', genre => 'surrealist' );
    my %more    = ( characters => ['Sam-I-Am', 'Guy-I-Am'], year => '1960' );
    my @list    = ('bar', 'foo');
    my @more    = ('qux', '💩');

    $log->debug($pattern, @values, \%data, \@list, \@more, \%more);

    my $wanted = {
        additional_messages => ['I do not like them, Sam-I-Am'],
        author              => 'Dr. Seuss',
        category            => 'main',
        genre               => 'surrealist',
        hash_data           => [
            {
                characters => ['Sam-I-Am', 'Guy-I-Am'],
                year       => '1960',
            },
        ],
        level               => 'debug',
        list_data           => [['bar', 'foo'], ['qux', '💩']],
        message             => 'Green Eggs and Ham',
        time                => re('^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{0,6}Z$'),
    };

    cmp_deeply( last_line(), $wanted, 'Structured data logged correctly');
};

##
done_testing;
