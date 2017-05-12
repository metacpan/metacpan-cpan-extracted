use warnings;
use strict;
use Test::More tests => 2;
use JSON::Parse qw/valid_json json_to_perl/;
my $json = <<EOF;
{
   "timed_out" : false,
   "took" : 3
}
EOF
ok (valid_json ($json), "valid json with extra whitespace");
eval {
    json_to_perl ($json);
};
ok (! $@, "No errors parsing JSON");
