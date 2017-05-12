use inc::Module::Install;

name		'List-Pairwise';
all_from	'lib/List/Pairwise.pm';

build_requires	'Test::More'	=> '0.42';

WriteAll;
