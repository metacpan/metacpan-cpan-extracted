use Test::More tests => 4;
BEGIN {
	
	use_ok('Dir::List');

	# TODO: Tests should be better!
	my $dir = new Dir::List;
	ok($dir != 0, 'new works');
	my $dirinfo = $dir->dirinfo('/tmp/');
	ok($dirinfo, 'dirinfo is defined');

	ok(1);
};
