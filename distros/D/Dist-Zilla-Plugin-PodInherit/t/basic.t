use strict;
use warnings;
use Test::DZil;
use Pod::POM;
use Test::More;

{
	my $tzil = Builder->from_config({
		dist_root => 't/dist'
	}, {
		add_files => {
			'source/dist.ini' => simple_ini('GatherDir', 'PodInherit'),
		}
	});
	$tzil->build;
	ok(!-e $tzil->tempdir->file('source/lib/ExampleClass/Subclass.pod'), 'no .pod created in source directory');
	ok(!-e $tzil->tempdir->file('build/lib/ExampleClass/Base.pod'), 'no .pod for a base class');
	ok(my $subclass = $tzil->slurp_file('build/lib/ExampleClass/Subclass.pod'), 'read output POD');
	my $parser = Pod::POM->new;
	ok(my $pom = $parser->parse_text($subclass), 'parse POD') or die $parser->error;
	my ($inherited, @extra) = (grep $_->title eq 'INHERITED METHODS', $pom->head1);
	is(@extra, 0, 'have single inherited methods section');
	like($inherited->content, qr/subclassed_method/, 'have subclass method link');
	like($inherited->content, qr/inherited_method/, 'have parent method link');
	unlike($inherited->content, qr/_private_method/, 'no private method link');
}
done_testing;
