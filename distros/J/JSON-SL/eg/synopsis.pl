use JSON::SL;
use Data::Dumper;

my $txt = <<'EOT';
{
    "some" : {
        "partial" : 42.42
    },
    "other" : {
        "partial" : "a string"
    },
    "complex" : {
        "partial": {
            "a key" : "a value"
        }
    },
    "more" : {
        "more" : "stuff"
EOT

my $json = JSON::SL->new();
my $jpath = "/^/partial";
$json->set_jsonpointer( [$jpath] );
my @results = $json->feed($txt);

foreach my $result (@results) {
    printf("== Got result (path %s) ==\n", $result->{Path});
    printf("Query was %s\n", $result->{JSONPointer});
    my $value = $result->{Value};
    if (!ref $value) {
        printf("Got scalar value %s\n", $value);
    } else {
        printf("Got reference:\n");
        print Dumper($value);
    }
    print "\n";
}

