use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME             => 'File::Find::Rule::UnixPermissions',
			  AUTHOR           => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
			  VERSION_FROM     => 'lib/File/Find/Rule/UnixPermissions.pm',
			  ABSTRACT_FROM    => 'lib/File/Find/Rule/UnixPermissions.pm',
			  LICENSE          => 'artistic_2',
			  PL_FILES         => {},
			  MIN_PERL_VERSION => '5.006',
			  CONFIGURE_REQUIRES => {
									 'ExtUtils::MakeMaker' => '0',
									 },
			  BUILD_REQUIRES => {
								 'File::Find::Rule'=>'0',
								 'Fcntl'=>'0',
								 'Test::More'=>'0',
								 },
			  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean => { FILES => 'File-Find-Rule-UnixPermissions-*' },
			  );
