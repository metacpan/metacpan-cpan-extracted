use warnings;
use strict;
use JSON::Parse qw/json_to_perl parse_json/;
use Test::More;

my $p;

# This was causing some problems with the new grammar / lexer.

my $jeplus = '[1.9e+9]';
eval {
    $p = json_to_perl ($jeplus);
};
#note ($@);
ok (! $@, "Parsed $jeplus OK");

my $j = <<EOF;
{
   "integer":100,
   "decimal":1.5,
   "fraction":0.01,
   "exponent-":1.9e-2,
   "exponent+":1.9e+9,
   "exponent":1.0E2
}
EOF
eval {
    $p = json_to_perl ($j);
};
#note ($@);
ok (! $@, "Parsed OK");

ok (compare ($p->{integer}, 100), "Got 100 for integer");
ok (compare ($p->{decimal} , 1.5), "Got 1.5 for decimal");
ok (compare ($p->{exponent} , 100), "Got 100 for exponent");
ok (compare ($p->{"exponent-"} , 19/1000), "got 19/1000 for exponent-");
ok (compare ($p->{"exponent+"} , 1_900_000_000),
    "got 1_900_000_000 for exponent+");
ok (compare ($p->{fraction} , 0.01), "got 0.01 for fraction");
my $q = @{json_to_perl ('[0.12345]')}[0];
ok (compare ($q, '0.12345'), "Got 0.12345");

# Illegal numbers

eval {
    json_to_perl ('[0...111]');
};
ok ($@, "Don't accept 0...111");
eval {
    json_to_perl ('[0111]');
};
like ($@, qr/unexpected character/i, "Error for leading zero");

my $long_number = '12345678901234567890123456789012345678901234567890';
my $out = parse_json ("[$long_number]");
is ($out->[0], $long_number);

done_testing;
exit;

sub compare
{
    my ($x, $y) = @_;
    my $error = 0.00001;
    if (abs ($x - $y) < $error) {
        return 1;
    }
    print "$x and $y are not equal.\n";
    return;
}
