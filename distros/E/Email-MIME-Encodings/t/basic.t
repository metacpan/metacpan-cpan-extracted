use Test::More tests => 12;
use_ok("Email::MIME::Encodings");

my $CRLF = "\x0d\x0a";
my $x = "This is a test${CRLF}of various MIME=stuff.";
for (qw(binary 7bit 8bit)) {
    is(Email::MIME::Encodings::encode($_, $x), $x, "enc $_");
    is(Email::MIME::Encodings::decode($_, $x), $x, "dec $_");
}

$y = "This is a test${CRLF}of various MIME=3Dstuff.=${CRLF}";
is(Email::MIME::Encodings::encode(quotedprint => $x), $y, "enc qp");
is(Email::MIME::Encodings::decode(quotedprint => $y), $x, "dec qp");

$z = "VGhpcyBpcyBhIHRlc3QNCm9mIHZhcmlvdXMgTUlNRT1zdHVmZi4=${CRLF}";
is(Email::MIME::Encodings::encode(base64 => $x), $z, "enc 64");
is(Email::MIME::Encodings::decode(base64 => $z), $x, "dec 64");

eval { 
    Email::MIME::Encodings::encode(foo => $x);
};

like ($@, qr/how to encode foo/, "Error handling");
