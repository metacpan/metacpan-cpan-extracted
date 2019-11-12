use Test::More tests => 13;

BEGIN { use_ok('IOLayer::MD5') }

my $file = 't/test.md5';

is( IOLayer::MD5->method,'hexdigest',	'check default method' );

ok( open( my $in,'<:Via(IOLayer::MD5)', $file ), "opening '$file' (hex)" );
is(
 scalar(<$in>),'340771c82e0ed1630baa47ce4138efb3',
 'check digest in scalar context'
);
ok( close( $in ),			'close handle (hex)' );

is( IOLayer::MD5->method( 'b64digest' ),'b64digest','check setting method' );
ok( open( my $in,'<:Via(IOLayer::MD5)', $file ), "opening '$file' (base64)" );
is( IOLayer::MD5->method( 'digest' ),'digest','check setting method' );

is( <$in>,'NAdxyC4O0WMLqkfOQTjvsw',	'check digest in list context' );
ok( close( $in ),			'close handle (base64)' );

ok( open( my $in,'<:Via(IOLayer::MD5)', $file ), "opening '$file' (binary)" );
is( <$in>,'4qÈ.ÑcªGÎA8ï³',	'check digest in list context' );
ok( close( $in ),			'close handle (binary)' );
