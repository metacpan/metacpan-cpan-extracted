use FindBin '$Bin';
use lib "$Bin";
use JPT;
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
done_testing ();
