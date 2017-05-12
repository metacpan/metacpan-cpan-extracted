#!perl
use strict;
use warnings;

use Test::More 0.88;

use Test::DZil;
use Path::Class;

{
	my $tzil = Builder->from_config(
	  { dist_root => 'corpus/' },
	  {
		  add_files => {
			  'source/dist.ini' => simple_ini(
				  qw/@Basic PkgVersion PPPort/
			  ),
		  },
	  },
	);

	$tzil->build;

	my $dir = dir($tzil->tempdir, 'build');

	ok -e $dir->file('ppport.h');
	ok -s $dir->file('ppport.h');
}

{
	my $tzil = Builder->from_config(
	  {
		  dist_root => 'corpus/',
	  },
	  {
		  add_files => {
			  'source/dist.ini' => simple_ini(
				  { name => 'Foo-Bar' },
				  qw/@Basic PkgVersion/,
				  [ PPPort => { style => 'ModuleBuild' } ],
			  ),
		  },
	  },
	);

	$tzil->build;

	my $dir = dir($tzil->tempdir, 'build');

	ok -e $dir->file('lib/Foo/ppport.h');
	ok -s $dir->file('lib/Foo/ppport.h');
}

done_testing;
