use Test::More tests => 3;
use JSON;
use JSON::XS;

my $perl = {
    unquoted => 1997,
    quoted => "1997",
};

my $json = objToJson($perl);
my $json_xs = to_json($perl);

isnt($json, $json_xs, "Confirm that JSON::XS encodes differently from JSON");
like($json_xs, qr/"quoted":"1997"/, "JSON::XS maintains quoted ints");
like($json,    qr/"quoted":1997/, "JSON doesn't maintain quoted ints");
