use 5.012;
use warnings;
use Test::More;
use Encode();
use Encode::Base2N qw/encode_base64 encode_base64url encode_base64pad decode_base64/;

my $ok = eval {
    require MIME::Base64;
    1;
};

plan skip_all => 'MIME::Base64 required for testing' unless $ok;

my $str = join('', map {chr($_)} 0..255);

my $enc = encode_base64($str);
my $encu = encode_base64url($str);
my $encp = encode_base64pad($str);

my $encpR = MIME::Base64::encode_base64($str, "");
my $encuR = MIME::Base64::encode_base64url($str, "");

is($encpR, $encp);
is($encuR, $encu);

is($enc, nopad($encpR));

is(decode_base64($enc), $str);
is(decode_base64($encu), $str);
is(decode_base64($encp), $str);

#rus
$str = "жопа нах";
is(length($str), 15);
$enc = encode_base64($str);
is($enc, nopad(MIME::Base64::encode_base64($str, "")));
is(decode_base64($enc), $str);

done_testing();

sub nopad {
	my $str = shift;
	$str =~ s/=+$//;
	return $str;
}
