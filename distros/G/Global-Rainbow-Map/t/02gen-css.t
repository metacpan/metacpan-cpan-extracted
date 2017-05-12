use Test::More tests => 1;
use Global::Rainbow::Map;

my $map = Global::Rainbow::Map->new(
	gb   => 'red',
	fr   => 'blue',
	de   => 'green',
);

is($map->generate_css, <<'EXPECTED');
.de {
	fill: #008000;
	opacity: 1;
}
.fr {
	fill: #0000ff;
	opacity: 1;
}
.gb {
	fill: #ff0000;
	opacity: 1;
}
EXPECTED
