use strict;
use warnings;
use Test::More tests => 3;

use MIME::Words qw(decode_mimewords);

my $str = '=?' x 2000;
my $dec = decode_mimewords($str);
my $err = $@;
is($dec, $str, 'Unterminated "=?" is kept as text');
like($err, qr/unterminated/, 'Unterminated "=?" is reported');
ok(length($err) < 100_000, 'Error text grows linearly with the input');
