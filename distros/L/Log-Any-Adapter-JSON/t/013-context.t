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

$log->context->{context} = 'here & now';

##
subtest 'plain string' => sub {
    $log->debug('hello, world');

    cmp_deeply(
        last_line(),
        {
            message  => 'hello, world',
            category => 'main',
            context  => 'here & now',
            level    => 'debug',
            time     => re('^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{0,5}$'),
        },
        'plain string logged as-is',
    );
};

##
subtest 'structured data' => sub {
    $log->debug('Some message', { foo => 'bar'}, { baz => 'qux'});

    my $wanted = {
        category => 'main',
        context   => 'here & now',
        hash_data => [
            {
                baz => 'qux',
            },
        ],
        foo       => 'bar',
        level     => 'debug',
        message   => 'Some message',
        time      => re('^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{0,5}$'),
    };
explain last_line();

    cmp_deeply( last_line(), $wanted, 'Structured data logged correctly');
};

##
done_testing;
