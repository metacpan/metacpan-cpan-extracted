use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
use Encode 'decode_utf8';
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use JSON::Parse 'parse_json';
my $j = '{"a":1, "a":2}';
my $p = parse_json ($j);
cmp_ok ($p->{a}, '==', 2, "Test documented hash key collision behaviour");

my $j2 = '{"a":1, "a":2, "a":3, "a":4, "a":5, "a":6, "a":7, "a":8, "a":9, "a":10}';
my $p2 = parse_json ($j2);
cmp_ok ($p2->{a}, '==', 10, "Test documented hash key collision behaviour");

my $focus = '{"hocus":10,"pocus":20,"hocus":30,"focus":40}';
my $jp = JSON::Parse->new ();
$jp->detect_collisions (1);
eval {
    $jp->run ($focus);
};
ok ($@);
like ($@, qr/"hocus"/);

my $yodi = '{"ほかす":10,"ぽかす":20,"ほかす":30,"ふぉかす":40}';
eval {
    $jp->run ($yodi);
};
ok ($@);
my $error = decode_utf8 ($@);
like ($error, qr/"ほかす"/);

note ($error);
done_testing ();
