# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 5;
    BEGIN { use_ok('HTML::TagParser') };
# ----------------------------------------------------------------
    my $SOURCE = <<EOT;
<html>
<body>
<div id="foo">
	<span>AAA</span>
	<div id="bar">
		BBB
		<span>CCC</span>
		DDD
		<div/>
		EEE
	</div>
	<span>FFF</span>
</div>
</body>
</html>
EOT
# ----------------------------------------------------------------
    my $html = HTML::TagParser->new( $SOURCE );
    ok( ref $html, "new()" );

	my $body = $html->getElementsByTagName( "body" );
	like( $body->innerText(), qr/AAA.*BBB.*CCC.*DDD.*EEE.*FFF/s, "body" );

	my $foo = $html->getElementById( "foo" );
#	like( $foo->innerText(), qr/AAA/s, "foo" );
	like( $foo->innerText(), qr/AAA.*BBB.*CCC.*DDD.*EEE.*FFF/s, "foo" );

	my $bar = $html->getElementById( "bar" );
#	like( $bar->innerText(), qr/BBB.*CCC.*DDD\W*$/s, "bar" );
	like( $bar->innerText(), qr/BBB.*CCC.*DDD.*EEE/s, "bar" );
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
