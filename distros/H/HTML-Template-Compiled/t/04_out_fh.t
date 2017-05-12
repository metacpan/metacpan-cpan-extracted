use Test::More tests => 5;
BEGIN { use_ok('HTML::Template::Compiled') };
use lib 't';
use File::Spec;
use HTC_Utils qw($tdir &cdir &create_cache &remove_cache);
my $cache_dir = "cache04";
$cache_dir = create_cache($cache_dir);
my $out = File::Spec->catfile('t', 'templates', 'out_fh.htc.output04');
HTML::Template::Compiled->clear_filecache($cache_dir);
test('compile', 'clearcache');
test('filecache');
test('memcache', 'clearcache');
HTML::Template::Compiled->preload($cache_dir);
test('after preload', 'clearcache');

sub test {
	my ($type, $clearcache) = @_;
	# test output($fh)
	my $htc = HTML::Template::Compiled->new(
		path => 't/templates',
		filename => 'out_fh.htc',
		out_fh => 1,
		file_cache_dir => $cache_dir,
        file_cache => 1,
	);
	open my $fh, '>', $out or die $!;
	$htc->output($fh);
	close $fh;
	open my $f, '<', File::Spec->catfile('t', 'templates', 'out_fh.htc') or die $!;
	open my $t, '<', $out or die $!;
	local $/;
	my $orig = <$f>;
	my $test = <$t>;
	for ($orig, $test) {
		tr/\n\r//d;
	}
	ok($orig eq $test, "out_fh $type");
	$htc->clear_cache() if $clearcache;

	# this is not portable
	#ok(-s $out == -s File::Spec->catfile('t', 'out_fh.htc'), "out_fh");
}

unlink $out;
HTML::Template::Compiled->clear_filecache($cache_dir);
remove_cache($cache_dir);
