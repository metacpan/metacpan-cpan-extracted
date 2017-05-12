# ----------------------------------------------------------------
use strict;
use Test::More tests => 8;
BEGIN { use_ok('HTML::TagParser') };
# ----------------------------------------------------------------

my $SOURCE = <<EOT;
<html>
<body>
<div id="foo">
	<span>AAA</span>
	<div id="bar"selected>
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

my $document = HTML::TagParser->new( $SOURCE );
ok( ref $document, "new()" );
my $bar = $document->getElementById('bar');
my $fff = $bar->nextSibling();
like( $fff->innerText(), qr/FFF/s, "nextSibling" );
is( $fff->nextSibling(), undef, "no nextSibling" );
my $ch = $bar->childNodes();
is( $#$ch, 1, "childNodes" );
is( $ch->[1]->parentNode()->id(), "bar", "parentNode" );
is( $ch->[1]->parentNode()->parentNode()->id(), "foo", "parent.parentNode" );
is( $ch->[1]->parentNode()->parentNode()->parentNode->parentNode()->parentNode(), undef, "root parentNode" );

# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
