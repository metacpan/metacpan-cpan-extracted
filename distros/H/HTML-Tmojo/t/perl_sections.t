use Test::More tests => 3;
BEGIN { use_ok('HTML::Tmojo') };

# MAKE A CACHE DIR
`rm -r t/cache`;
mkdir 't/cache';

# CREATE THE TMOJO OBJECT
my $tmojo = HTML::Tmojo->new(
	template_dir => 't/templates',
	cache_dir    => 't/cache',
);

is($tmojo->call('perl_sections_1.tmojo'), '260', 'perl_sections_1');

is($tmojo->call('perl_sections_2.tmojo'), "\n\tx is bigger than 1", 'perl_sections_2');