use Test::More tests => 4;
BEGIN { use_ok('HTML::Tmojo') };


# MAKE A CACHE DIR
`rm -r t/cache`;
mkdir 't/cache';

# CREATE THE TMOJO OBJECT
my $tmojo = HTML::Tmojo->new(
	template_dir => 't/templates',
	cache_dir    => 't/cache',
);

is($tmojo->call('hello.tmojo'), 'Hello, World!', 'hello');

is($tmojo->call('hello_2.tmojo', name => 'Foo'), 'Hello, Foo!', 'hello_2');

is($tmojo->call('hello_2.tmojo', name => '!@#$!@#$'), 'Hello, !@#$!@#$!', 'hello_3');