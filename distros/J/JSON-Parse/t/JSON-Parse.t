# This is a basic test of parsing JSON. See also Json3.t.

use FindBin '$Bin';
use lib "$Bin";
use JPT;

my $jason = <<'EOF';
{"bog":"log","frog":[1,2,3],"guff":{"x":"y","z":"monkey","t":[0,1,2.3,4,59999]}}
EOF
my $x = parse_json ($jason);
note ($x->{guff}->{t}->[2]);
cmp_ok (abs ($x->{guff}->{t}->[2] - 2.3), '<', 0.00001, "Two point three");
my $xs = parse_json_safe ($jason);
note ($xs->{guff}->{t}->[2]);
cmp_ok (abs ($xs->{guff}->{t}->[2] - 2.3), '<', 0.00001, "Two point three");

my $fleece = '{"凄い":"技", "tickle":"baby"}';
my $y = parse_json ($fleece);
ok ($y->{tickle} eq 'baby', "Parse hash");
my $ys = parse_json_safe ($fleece);
ok ($ys->{tickle} eq 'baby', "Parse hash");

ok (valid_json ($fleece), "Valid OK JSON");

my $argonauts = '{"medea":{"magic":true,"nice":false}}';
my $z = parse_json ($argonauts);
ok ($z->{medea}->{magic}, "Parse true literal.");
ok (! ($z->{medea}->{nice}), "Parse false literal.");
my $zs = parse_json_safe ($argonauts);
ok ($zs->{medea}->{magic}, "Parse true literal.");
ok (! ($zs->{medea}->{nice}), "Parse false literal.");

ok (valid_json ($argonauts), "Valid OK JSON");

# Test that empty inputs result in an error message.

eval {
    my $Q = parse_json ('');
};
ok ($@, "Empty string makes error");
ok ($@ =~ /empty input/i, "Empty input error for empty input");
eval {
    # Switch off uninitialized value warning for this test.
    no warnings;
    my $R = parse_json (undef);
};
ok ($@, "Empty string makes error");
ok ($@ =~ /empty input/i, "Empty input error for empty input");
eval {
    my $S = parse_json ('    ');
};
ok ($@, "Empty string makes error");
ok ($@ =~ /empty input/i, "Empty input error for empty input");

# Test that errors are produced if we are missing the final brace.

my $n;
eval {
    $n = '{"骪":"\u9aaa"';
    my $nar = parse_json ($n);
};
ok ($@, "found error");
{
    my $warning;
    local $SIG{__WARN__} = sub {
	$warning = $_[0];
    };
    eval {
	$n = '{"骪":"\u9aaa"';
	my $nar = parse_json_safe ($n);
    };
    ok (! $@, "no exception with parse_json_safe");
    unlike ($warning, qr/\n.+/, "no newlines in middle of error");
    like ($warning, qr/JSON-Parse\.t/, "right file name for error");
}

ok (! valid_json ($n), "! Not valid missing end }");

# Test that errors are produced if we are missing the initial brace {.

my $bad1 = '"bad":"city"}';
$@ = undef;
eval {
    parse_json ($bad1);
};
ok ($@, "found error in '$bad1'");
my $notjson = 'this is not lexable';
$@ = undef;
eval {
    parse_json ($notjson);
};
ok ($@, "Got error message");
ok (! valid_json ($notjson), "Not valid bad json");

# This is the example from either the JSON RFC or from Douglas
# Crockford's web page.

my $wi =<<EOF;
{
     "firstName": "John",
     "lastName": "Smith",
     "age": 25,
     "address":
     {
         "streetAddress": "21 2nd Street",
         "city": "New York",
         "state": "NY",
         "postalCode": "10021"
     },
     "phoneNumber":
     [
         {
           "type": "home",
           "number": "212 555-1234"
         },
         {
           "type": "fax",
           "number": "646 555-4567"
         }
     ]
 }
EOF
my $xi = parse_json ($wi);
ok ($xi->{address}->{postalCode} eq '10021', "Test a value $xi->{address}->{postalCode}");
ok (valid_json ($wi), "Validate");

my $perl_a = parse_json ('["a", "b", "c"]');
ok (ref $perl_a eq 'ARRAY', "json array to perl array");
my $perl_b = parse_json ('{"a":1, "b":2}');
ok (ref $perl_b eq 'HASH', "json object to perl hash");

done_testing ();

exit;

