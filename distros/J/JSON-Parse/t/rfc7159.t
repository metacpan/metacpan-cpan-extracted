use warnings;
use strict;
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use JSON::Parse qw/parse_json valid_json/;
my $stringonly = '"this"';
my $j;
eval {
    $j = parse_json ($stringonly);
};
ok (! $@, "no errors parsing rfc7159 json");
is ($j, 'this', "Got correct value as well");
ok (valid_json ($stringonly), "And it's valid json too");

my $numberonly = '3.14';
my $j2;
eval {
    $j2 = parse_json ($numberonly);
};
ok (! $@, "no errors parsing rfc7159 json");
cmp_ok (abs ($j2 - $numberonly), '<', 0.0001, "got number back");
ok (valid_json ($numberonly), "And it's valid JSON too");

my $numberonly2 = '0.14';
my $jx;
eval {
    $jx = parse_json ($numberonly2);
};
ok (! $@, "no errors parsing rfc7159 json $numberonly2");
cmp_ok (abs ($jx - ($numberonly2 + 0.0)), '<', 0.0001, "got number back $numberonly2");
ok (valid_json ($numberonly2), "And it's valid JSON too");

my $numberws = '  5.55e10  ';
ok (valid_json ($numberws), "$numberws validated");
my $literalws = '   true  ';
ok (valid_json ($literalws), "'$literalws' validates");
my $j3;
eval {
    $j3 = parse_json ($literalws);
};
ok (! $@, "no errors parsing '$literalws'");
ok ($j3, "'$literalws' gives a true value");
is ($j3, 1, "'$literalws' is equal to one");
my $literal = 'null';
ok (valid_json ($literal), "'$literal' validates");
my $j4;
eval {
    $j4 = parse_json ($literal);
};
ok (! $@, "no errors parsing '$literal'");
ok (! $j4, "bare literal null is false value");
ok (! defined ($j4), "bare literal null is undefined");

 
done_testing ();
