
use Test::More tests => 1;
use JSON::Streaming::Reader::TestUtil;

# Test that the callback API generates the same results as the pull API
# (since we already tested the pull API in a previous script)

my @pull_tokens;
my @callback_tokens;

my $input = join('', <DATA>);

my $jsonr = JSON::Streaming::Reader->for_string($input);

while (my $token = $jsonr->get_token()) {
    push @pull_tokens, $token;
}

my %callbacks = ();
foreach my $callback_name (qw(start_object end_object start_array end_array start_property end_property add_string add_number add_boolean add_null error)) {
    $callbacks{$callback_name} = sub {
        push @callback_tokens, [ $callback_name, @_ ];
    };
}

# Now make another one so we can start fresh with the callback API.
$jsonr = JSON::Streaming::Reader->for_string($input);

$jsonr->process_tokens(%callbacks);

is_deeply(\@callback_tokens, \@pull_tokens, "Callback API output matches pull API output");

__END__

{
    "number": 1,
    "string": "hello",
    "boolean": true,
    "null": null,
    "array": [
        1, "hello", true, null, [], {}
    ],
    "object": {
        "number": 1,
        "string": "hello",
        "boolean": true,
        "null": null,
        "array": [],
        "object": {}
    },
    error

}

