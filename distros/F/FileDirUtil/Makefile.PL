use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME              => 'FileDirUtil',
	      VERSION_FROM      => 'lib/FileDirUtil.pm',
	      ABSTRACT_FROM     => 'lib/FileDirUtil.pm',
	      PREREQ_PM         => {
				    "Moose" => '0',
				    "Moose::Util::TypeConstraints" => '0',
				    "Moose::Role" => '0',
				    "File::Basename" => '0',
				    "Path::Class::File" => '0',
				    "Path::Class::Dir" => '0',
				    "namespace::autoclean" => '0',
				   },
	      AUTHOR            => 'Michael T. Wolfinger <michael@wolfinger.eu>',
	      LICENSE           => 'agpl_3',
	      CONFIGURE_REQUIRES => {
				     'ExtUtils::MakeMaker' => 0,
				    },
	      BUILD_REQUIRES     => {
				     'Test::More' => 0,
				    },
	      dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean => { FILES => 'Bio-RNA-AliSplit-*' },
	     );
