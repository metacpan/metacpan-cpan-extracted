use warnings;
use strict;
use Test::More;
use JSON::Parse qw/json_to_perl valid_json parse_json/;
use utf8;
binmode STDOUT, ":utf8";
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $m = '{"骪":"\u9aaa"}';
ok (valid_json ($m), "Valid good JSON");

my $ar = json_to_perl ($m);
ok (defined $ar, "Unicode \\uXXXX parsed");
is ($ar->{骪}, '骪', "Unicode \\uXXXX parsed correctly");
note ("keys = ", keys %$ar);

# Here the second unicode piece of the string is added to switch on
# the UTF-8 flag inside Perl and get the required invalidity. 

my $badunicode = '["\uD800", "バター"]';
ok (! valid_json ($badunicode), "$badunicode is invalid");

# This is what the documentation says will happen. However, I'm not
# sure this is correct or what the user expects to happen.

my $okunicode = '["\uD800"]';
ok (! valid_json ($okunicode), "$okunicode is valid");

my $surpair = '["\uD834\uDD1E"]';
my $spo;
eval {
    $spo = parse_json ($surpair);
};
ok (! $@, "parsed surrogate pairs");
is (ord ($spo->[0]), 0x1D11E, "g-clef surrogate pair");

use utf8;
my $surpair_force_utf8 = '["\uD834\uDD1E麻婆茄子"]';
my $spo_force_utf8;
eval {
    $spo_force_utf8 = parse_json ($surpair);
};
ok (! $@, "parsed surrogate pairs");
is (ord ($spo_force_utf8->[0]), 0x1D11E, "g-clef surrogate pair");

use utf8;
my $scorpion = '["蠍"]';
my $p1 = parse_json ($scorpion);
ok (utf8::is_utf8 ($p1->[0]), "UTF-8 survives");

no utf8;

my $ebi = '["蠍"]';
my $p2 = parse_json ($ebi);
ok (! utf8::is_utf8 ($p2->[0]), "Not UTF-8 not marked as UTF-8");

no utf8;
# 蟹
my $kani = '["\u87f9", "蟹", "\u87f9猿"]';
my $p = parse_json ($kani);
ok (utf8::is_utf8 ($p->[0]), "kani upgraded regardless");
ok (! utf8::is_utf8 ($p->[1]), "input string not upgraded, even though it's UTF-8");
ok (utf8::is_utf8 ($p->[2]), "upgrade this too");
is (length ($p->[2]), 2, "length is two by magic");

ok (! valid_json ('["\uDE8C "]'), "invalid \uDE8C + space");

# Test of the strangely-named "surrogate pairs".

my $jc = JSON::Parse->new ();
my $wikipedia_1 = '"\ud801\udc37"';
my $out_1 = $jc->run ($wikipedia_1);
is ($out_1, "\x{10437}");
my $wikipedia_2 = '"\ud852\udf62"';
my $out_2 = $jc->run ($wikipedia_2);
is ($out_2, "\x{24b62}");
my $json_spec = '"\ud834\udd1e"';
my $out_3 = $jc->run ($json_spec);
is ($out_3, "\x{1D11E}");

done_testing ();
