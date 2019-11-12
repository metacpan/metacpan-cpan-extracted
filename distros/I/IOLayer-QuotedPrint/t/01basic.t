use Test::More tests => 11;

BEGIN { use_ok('IOLayer::QuotedPrint') }

my $file = 't/test.qp';

my $decoded = <<EOD;
This is a tést for quoted-printable text that has hàrdly any speçial characters
in it.
EOD

my $encoded = <<EOD;
This is a t=E9st for quoted-printable text that has h=E0rdly any spe=E7ial =
characters
in it.
EOD

# Create the encoded test-file

ok(
 open( my $out,'>:Via(IOLayer::QuotedPrint)', $file ),
 "opening '$file' for writing"
);

ok( (print $out $decoded),		'print to file' );
ok( close( $out ),			'closing encoding handle' );

# Check encoding without layers

{
local $/ = undef;
ok( open( my $test,$file ),		'opening without layer' );
is( $encoded,readline( $test ),		'check encoded content' );
ok( close( $test ),			'close test handle' );
}

# Check decoding _with_ layers

ok(
 open( my $in,'<:Via(IOLayer::QuotedPrint)', $file ),
 "opening '$file' for reading"
);
is( $decoded,join( '',<$in> ),		'check decoding' );
ok( close( $in ),			'close decoding handle' );

# Remove whatever we created now

ok( unlink( $file ),			"remove test file '$file'" );
