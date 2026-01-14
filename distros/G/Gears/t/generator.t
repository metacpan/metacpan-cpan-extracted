use v5.40;
use Test2::V1 -ipP;
use Gears::Generator;
use Path::Tiny qw(path);

################################################################################
# This tests whether generator copies templates correctly
################################################################################

subtest 'should copy a template' => sub {
	my $generator = Gears::Generator->new(
		base_dir => 't',
		content_filters => [
			sub ($content) {
				return $content =~ s{TO_REMOVE\s*}{}r;
			},
		],
		name_filters => [
			sub ($name) {
				return $name =~ s{myapp}{generatedapp}r;
			}
		],
	);

	my $template = $generator->get_template('generator');
	check_paths(
		$template,
		[
			path('t/generator/myapp.pl'),
			path('t/generator/flat.txt'),
			path('t/generator/dir/nested.txt'),
		],
		'template files ok'
	);

	my $tmp_dir = Path::Tiny->tempdir;
	my $generated = $generator->generate('generator', $tmp_dir);

	check_paths(
		$generated,
		[
			$tmp_dir->child('generatedapp.pl'),
			$tmp_dir->child('flat.txt'),
			$tmp_dir->child('dir/nested.txt'),
		],
		'generated files ok'
	);

	ok !$tmp_dir->child('myapp.pl')->exists, 'old name changed ok';
	is $tmp_dir->child('generatedapp.pl')->slurp({binmode => ':encoding(UTF-8)'}),
		"some perl app\n", 'app content ok';
	is $tmp_dir->child('flat.txt')->slurp({binmode => ':encoding(UTF-8)'}),
		"file content\n", 'file content ok';
	is $tmp_dir->child('dir/nested.txt')->slurp({binmode => ':encoding(UTF-8)'}),
		"zażółć gęślą jaźń\n", 'unicode file content ok';
};

subtest 'should not override files when copying' => sub {
	my $generator = Gears::Generator->new(
		base_dir => 't',
	);

	my $ex = dies {
		$generator->generate('generator', 't/generator');
	};

	isa_ok $ex, 'Gears::X::Generator';
	like $ex, qr{\Qfile already exists: \E.+\Q, aborting\E}, 'exception ok';
};

done_testing;

sub check_paths ($got, $wanted, $name)
{
	my @got_copy = sort map { $_->stringify } $got->@*;
	my @wanted_copy = sort map { $_->stringify } $wanted->@*;

	is \@got_copy, \@wanted_copy, $name;
}

