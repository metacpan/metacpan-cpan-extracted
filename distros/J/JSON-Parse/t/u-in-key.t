use FindBin '$Bin';
use lib "$Bin";
use JPT;
my $test = <<'EOF';
{"\u0041":"A","\u3000":"　","\t":"tab"}
EOF
my $out = parse_json ($test);
TODO: {
    local $TODO = 'Support \u escapes in keys';
    ok ($out->{A}, "Got a key");
    is ($out->{A}, 'A', "Got right value for A");
    ok ($out->{'　'}, "Got U+3000 key");
    is ($out->{'　'}, '　', "Got right value for U+3000");
    ok ($out->{"\x{09}"}, "got a tab as key");
    is ($out->{"\x{09}"}, 'tab', "Got right value for tab as key");
};
done_testing ();
