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

use JSON::Create qw/create_json create_json_strict/;

# Test it with Perl's unicode flag switched on everywhere.

use utf8;

my %unihash = (
    'う' => '雨',
    'あ' => '亜',
);


for my $func (\&create_json, \&create_json_strict) {
    my $out = &{$func} (\%unihash);
    ok ($out, "Got output from Unicode hash");
    ok (utf8::is_utf8 ($out), "Output is marked as Unicode");
    # Key/value pairs may be in either order, so we have to use "like"
    # to test the key / value pairs.
    like ($out, qr/"う":"雨"/, "key / value pair u");
    like ($out, qr/"あ":"亜"/, "key / value pair a");
}


# Now test the other option, switch off the Perl unicode flag and
# check that it still works.

no utf8;

my %nonunihash = (
    'う' => '雨',
    'あ' => '亜',
);

my $nonuout = create_json (\%nonunihash);
ok ($nonuout, "Got output from unmarked Unicode hash");
ok (! utf8::is_utf8 ($nonuout), "Output is not marked as Unicode");
# Key/value pairs may be in either order, so we have to use "like"
# to test the key / value pairs.
like ($nonuout, qr/"う":"雨"/, "key / value pair u");
like ($nonuout, qr/"あ":"亜"/, "key / value pair a");
{
    my $warning;
    local $SIG{__WARN__} = sub {$warning = "@_"};
    my $nonuout = create_json_strict (\%nonunihash);
    is ($nonuout, undef, "Got undefined value sending non-Unicode bytes to strict routine");
    like ($warning, qr/Non-ASCII byte in non-utf8 string/);

    $warning = undef;

    my $jcs = JSON::Create->new ();
    $jcs->strict (1);
    my $nonuoutobj = $jcs->create (\%nonunihash);
    is ($nonuoutobj, undef, "Got undefined value sending non-Unicode bytes to strict object");
    like ($warning, qr/Non-ASCII byte in non-utf8 string/);

}

use utf8;

# There is a bug here, that we must actually validate all the UTF-8 in
# the code when the Perl flag is switched off, otherwise we may
# produce invalid JSON.

# Test the escaping of U+2028 and U+2029
{
    my $jc = JSON::Create->new ();

    my $in2028 = "\x{2028}";
    my $out2028 = $jc->create ($in2028);
    is ($out2028, '"\u2028"', "default JS protection");

    my $in2029 = "\x{2029}";
    my $out2029 = $jc->create ($in2029);
    is ($out2029, '"\u2029"', "default JS protection");

    # Test that i is being incremented.

    my $mixed = "\x{2028}\x{02a7}\x{2029}\x{3074}\x{2029}m\x{2028}";
    my $outmixed = $jc->create ($mixed);
    is ($outmixed, '"\u2028ʧ\u2029ぴ\u2029m\u2028"', "default JS protection");

    $jc->no_javascript_safe (1);

    my $out2028a = $jc->create ($in2028);
    is ($out2028a, "\"\x{2028}\"", "switch off JS protection");

    my $out2029a = $jc->create ($in2029);
    is ($out2029a, "\"\x{2029}\"", "switch off JS protection");

    $jc->no_javascript_safe (0);

    my $out2028b = $jc->create ($in2028);
    is ($out2028b, '"\u2028"', "switch on JS protection");

    my $out2029b = $jc->create ($in2029);
    is ($out2029b, '"\u2029"', "switch on JS protection");
};

# Test the unicode_escape_all
{
    my $jc = JSON::Create->new ();
    $jc->unicode_escape_all (1);
    $jc->unicode_upper (0);

    use utf8;

    my $in = '赤ブöＡↂϪ';
    my $out = $jc->create ($in);
    is ($out, '"\u8d64\u30d6\u00f6\uff21\u2182\u03ea"', "Unicode escaping");

    $jc->unicode_upper (1);

    my $out2 = $jc->create ($in);
    is ($out2, '"\u8D64\u30D6\u00F6\uFF21\u2182\u03EA"',
	"Upper case hex unicode");
};

# Test the generation of surrogate pairs
{
    my $jc = JSON::Create->new ();
    $jc->unicode_escape_all (1);
    $jc->unicode_upper (0);

    # These are exactly the same examples as in "unicode.c", please
    # see that code for links to where the examples come from.

    my $wikipedia_1 = "\x{10437}";
    my $out_1 = $jc->create ($wikipedia_1);
    is ($out_1, '"\ud801\udc37"', "surrogate pair wiki 1");

    my $wikipedia_2 = "\x{24b62}";
    my $out_2 = $jc->create ($wikipedia_2);
    is ($out_2, '"\ud852\udf62"', "surrogate pair wiki 2");

    my $json_spec = "\x{1D11E}";
    my $out_3 = $jc->create ($json_spec);
    is ($out_3, '"\ud834\udd1e"', "surrogate pair json spec");

    my $combined = "\x{10437}\x{24b62}\x{1D11E}\x{10437}x\x{24b62}y\x{1D11E}z";
    my $out_combined = $jc->create ($combined);
    is ($out_combined, '"\ud801\udc37\ud852\udf62\ud834\udd1e\ud801\udc37x\ud852\udf62y\ud834\udd1ez"',
	"combination of things");
    $jc->unicode_escape_all (0);
    my $out_combined_noesc = $jc->create ($combined);
    is ($out_combined_noesc, '"'.$combined.'"', "Long UTF-8 processed OK");
};

# Test the generation of escapes
{
    my $jc = JSON::Create->new ();
    my $bad_utf8 = "\x{99}\x{ff}";
    $jc->fatal_errors (1);
    eval {
	$jc->create ($bad_utf8);
    };
    ok ($@, "Got error with bad UTF-8");
    $jc->replace_bad_utf8 (1);
    my $outreplaced;
    eval {
	$outreplaced = $jc->create ($bad_utf8);
    };
    ok (! $@, "No error with bad UTF-8 and replacement");
    is ($outreplaced, "\"\x{fffd}\x{fffd}\"");
};

done_testing ();

exit;
