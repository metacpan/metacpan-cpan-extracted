#!perl

use v5.26;
use warnings;
use lib 'lib';

use Test::DZil;
use Test::More;

plan tests => 6;


sub built_version_like {
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my ($version, $re, $name) = @_;
	
	my $content = "#\n\nclass Version;";
	my $tzil = Builder->from_config(
		{ dist_root => 't/corpus' },
		{ add_files => {
			'source/lib/Version.pm' => $content,
			'source/dist.ini' => simple_ini( { version => $version },
				'GatherDir',
				'ExplicitPackageForClass',
			),
		}},
	);
	$tzil->build or do { fail "$name (build)"; return };
	
	$re = qr{\Q$re\E} unless ref $re eq 'Regexp';
	like $tzil->slurp_file('build/lib/Version.pm'), $re, $name;
}


built_version_like 'v2.345.6', " v2.345.6;\n", 'strict v-string';
built_version_like '2.3456',   " 2.3456;\n",   'strict decimal';

built_version_like 'v1.2',     " v1.2;\n",     'lax v-string';
built_version_like '1.234.5',  " 1.234.5;\n",  'lax dotted-decimal';

built_version_like 'v1.23_4',  " v1.234; # TRIAL\n", 'trial v-string';
built_version_like '1.23_45',  " 1.2345; # TRIAL\n", 'trial decimal';


done_testing;
