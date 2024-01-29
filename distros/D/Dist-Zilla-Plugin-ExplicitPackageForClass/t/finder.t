#!perl

use v5.26;
use warnings;
use lib 'lib';

use Test::DZil;
use Test::More;

plan tests => 3;



sub built_module_like {
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my ($file, $content, $re, $name) = @_;
	
	my $tzil = Builder->from_config(
		{ dist_root => 't/corpus' },
		{ add_files => {
			"source/lib/$file" => $content,
			"source/dist.ini" => simple_ini( {},
				'GatherDir',
				['FileFinder::ByName', 'MyFinder' => {
					match => 'Class',
					skip => 'Skip',
				}],
				['ExplicitPackageForClass' => {
					finder => 'MyFinder',
				}],
			),
		}},
	);
	$tzil->build or do { fail "$name (build)"; return };
	
	like $tzil->slurp_file("build/lib/$file"), $re, $name;
}



built_module_like 'Class/Module.pm', <<END,
...;

class Class::Module;
END
	qr{^package Class::Module [v0-9.]+;$}m,
	'custom file finder: Class';



built_module_like 'Class/Skip.pm', <<END,
# empty line contains two spaces (which will NOT be overwritten)
...;
  
class Class::Skip;
END
	qr{...;\n  }s,
	'custom file finder: skip Class';



built_module_like 'Foo.pm', <<END,
# empty line contains two spaces (which will NOT be overwritten)
...;
  
class Foo;
END
	qr{...;\n  }s,
	'custom file finder: no Class';



done_testing;
