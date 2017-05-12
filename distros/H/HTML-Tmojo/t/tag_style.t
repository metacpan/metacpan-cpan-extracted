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

my $val = qq{Var is: 1
Var is: 2
Var is: 3
Var is: 4
Var is: 5
};

is($tmojo->call('tag_style.tmojo'), $val, 'tag_style');