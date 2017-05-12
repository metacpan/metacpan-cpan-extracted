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

my $val = qq{Title:  Document Title
Author: Will Conant

This is a supposed document written
by Will Conant.
__END__};

is($tmojo->call('contained_1.tmojo'), $val, 'containers_1');