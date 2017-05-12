use Test::More tests => 2;
BEGIN { use_ok('HTML::Tmojo') };

# MAKE A CACHE DIR
`rm -r t/cache`;
mkdir 't/cache';

# CREATE THE TMOJO OBJECT
my $tmojo = HTML::Tmojo->new(
	template_dir => 't/templates',
	cache_dir    => 't/cache',
);

my $val = qq{<title>Test Document</title>

<body>
	Dear Will Conant,
	
	This is a simple test letter that
	uses methods.
</body>};

is($tmojo->call('methods_1.tmojo'), $val, 'methods_1');