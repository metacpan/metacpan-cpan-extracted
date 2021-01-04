use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use JSON::Create 'write_json';
use JSON::Parse 'json_file_to_perl';
my $out = "$Bin/test-write-json.json";
if (-f $out) {
    unlink $out or warn "Failed to unlink $out: $!";
}
# It's your thing.
my $thing = {a => 'b', c => 'd'};
write_json ($out, $thing);
ok (-f $out, "Wrote a file");
my $roundtrip = json_file_to_perl ($out);
is_deeply ($roundtrip, $thing);
if (-f $out) {
    unlink $out or warn "Failed to unlink $out: $!";
}
done_testing ();
