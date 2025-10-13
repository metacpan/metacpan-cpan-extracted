use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

sub run_query {
    my ($json, $query) = @_;
    return [ $jq->run_query($json, $query) ];
}

subtest 'pick on single object' => sub {
    my $json    = '{"name":"Alice","age":30,"city":"Paris"}';
    my $results = run_query($json, 'pick("name", "age")');

    is_deeply(
        $results->[0],
        { name => 'Alice', age => 30 },
        'returns subset of keys'
    );
};

subtest 'pick on array of objects' => sub {
    my $json    = '{"users":[{"name":"Alice","age":30,"email":"alice@example.com"},{"name":"Bob","age":27}]}';
    my $results = run_query($json, '.users | pick("name", "email")');

    is_deeply(
        $results->[0],
        [
            { name => 'Alice', email => 'alice@example.com' },
            { name => 'Bob' },
        ],
        'applies selection to each array element'
    );
};

subtest 'pick leaves non-objects unchanged' => sub {
    my $json    = '{"value":"hello"}';
    my $results = run_query($json, '.value | pick("anything")');

    is($results->[0], 'hello', 'non-object value is passed through');
};

done_testing();
