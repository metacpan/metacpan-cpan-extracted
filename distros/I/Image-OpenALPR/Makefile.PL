use 5.014000;
use Devel::CheckLib;
use ExtUtils::MakeMaker;

check_lib_or_exit
  lib => 'openalprpy';

WriteMakefile(
	NAME              => 'Image::OpenALPR',
	VERSION_FROM      => 'lib/Image/OpenALPR.pm',
	ABSTRACT_FROM     => 'lib/Image/OpenALPR.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'open_source',
	SIGN              => 1,
	CONFIGURE_REQUIRES => {
		qw/Devel::CheckLib     0
		   ExtUtils::MakeMaker 0/,
	},
	PREREQ_PM         => {
		qw/Class::Accessor::Fast 0
		   JSON::MaybeXS 0/,
	},
	LIBS              => ['-lopenalprpy'],
	META_ADD          => {
		dynamic_config => 1,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=image-openalpr.git',
		},
	}
);
